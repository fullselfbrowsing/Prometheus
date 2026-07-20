import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';

import {
  FIXTURE_CHILD_TEXT,
  FIXTURE_MODEL_ID,
  FIXTURE_PAGE_TEXT,
  FIXTURE_PROVIDER_TEXT,
  FIXTURE_PROVIDER_TOOL,
  FIXTURE_PROVIDER_TOOLS,
  MAX_FIXTURE_PROVIDER_REQUEST_BYTES,
  startFixtureServer,
} from './fixture-server.mjs';
import {
  BridgeProcess,
  DIAGNOSTIC_KEYS,
  RPC_TIMEOUT_MS,
  assertCompatibilityInventory,
  assertDiagnosticInventory,
  assertRemovedToolResult,
  assertSafeCapturedOutput,
  assertSafeProtocolResponses,
} from './smoke-client.mjs';

const withTempDirectory = async (callback) => {
  const directory = await mkdtemp(path.join(tmpdir(), 'prometheus-mcp-smoke-test-'));
  try {
    return await callback(directory);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
};

const fakeBridgeSource = String.raw`
import { createInterface } from 'node:readline';

const tools = Array.from({ length: 90 }, (_, index) => ({
  name: index === 0 ? 'diagnostics' : 'tool_' + String(index).padStart(2, '0'),
  description: 'fixture',
  inputSchema: { type: 'object', properties: {}, additionalProperties: false },
}));

const send = (message) => process.stdout.write(JSON.stringify(message) + '\n');
const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
for await (const line of input) {
  const message = JSON.parse(line);
  if (!Object.hasOwn(message, 'id')) continue;
  if (message.method === 'initialize') {
    send({
      jsonrpc: '2.0',
      id: message.id,
      result: {
        protocolVersion: '2025-06-18',
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: 'prometheus-mcp', version: '2.0.0' },
      },
    });
  } else if (message.method === 'tools/list') {
    send({ jsonrpc: '2.0', id: message.id, result: { tools } });
  } else if (message.method === 'ping') {
    send({ jsonrpc: '2.0', id: message.id, result: {} });
  } else {
    send({ jsonrpc: '2.0', id: message.id, error: { code: -32601, message: 'unknown' } });
  }
}
`;

test('fixture server exposes deterministic page, attributes, mutation, and child frame', async () => {
  const fixture = await startFixtureServer();
  try {
    const response = await fetch(fixture.url);
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('cache-control'), 'no-store');
    const page = await response.text();
    assert.match(page, new RegExp(FIXTURE_PAGE_TEXT, 'u'));
    assert.match(page, /id="present-empty" data-empty=""/u);
    assert.doesNotMatch(page, /id="present-empty"[^>]*data-missing=/u);
    assert.match(page, /id="fixture-input"/u);
    assert.match(page, /id="fixture-button"/u);
    assert.match(page, /src="\/child"/u);

    const child = await fetch(new URL('/child', fixture.url));
    assert.equal(child.status, 200);
    assert.match(await child.text(), new RegExp(FIXTURE_CHILD_TEXT, 'u'));
  } finally {
    await fixture.close();
  }
});

test('fixture server exposes only bounded deterministic provider routes', async () => {
  const fixture = await startFixtureServer();
  const providerRequest = {
    model: FIXTURE_MODEL_ID,
    store: false,
    parallel_tool_calls: false,
    max_output_tokens: 128,
    instructions: 'Use the closed fixture tool.',
    input: [{ role: 'user', content: 'Read the bounded fixture page.' }],
    tools: FIXTURE_PROVIDER_TOOLS,
  };
  try {
    const models = await fetch(new URL('/v1/models', fixture.origin));
    assert.equal(models.status, 200);
    assert.deepEqual(await models.json(), { data: [{ id: FIXTURE_MODEL_ID }] });

    const response = await fetch(new URL('/v1/responses', fixture.origin), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(providerRequest),
    });
    assert.equal(response.status, 200);
    assert.deepEqual(
      FIXTURE_PROVIDER_TOOLS.map(({ name }) => name),
      [
        'read_page',
        'get_page_snapshot',
        'click',
        'type_text',
        'press_key',
        'scroll',
        'hover',
        'select_option',
        'clear',
      ],
    );
    const result = await response.json();
    assert.equal(result.status, 'completed');
    assert.deepEqual(result.usage, { input_tokens: 7, output_tokens: 3 });
    assert.equal(result.output[0].content[0].text, FIXTURE_PROVIDER_TEXT);
    assert.deepEqual(result.output[1], {
      type: 'function_call',
      call_id: 'phase20-fixture-call',
      name: FIXTURE_PROVIDER_TOOL,
      arguments: '{}',
    });

    const rejected = await Promise.all([
      fetch(new URL('/v1/models', fixture.origin), {
        method: 'POST',
        body: '{}',
      }),
      fetch(new URL('/v1/responses', fixture.origin)),
      fetch(new URL('/v1/responses', fixture.origin), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: '{}',
      }),
      fetch(new URL('/v1/responses', fixture.origin), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...providerRequest,
          tools: providerRequest.tools.slice(0, 1),
        }),
      }),
      fetch(new URL('/v1/responses', fixture.origin), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: 'x'.repeat(MAX_FIXTURE_PROVIDER_REQUEST_BYTES + 1),
      }),
      fetch(new URL('/v1/unknown', fixture.origin)),
      fetch(new URL('/v1/models?unexpected=1', fixture.origin)),
    ]);
    assert.deepEqual(
      rejected.map(({ status }) => status),
      [405, 405, 400, 400, 413, 404, 404],
    );
  } finally {
    await fixture.close();
  }
});

test('independent bridge process speaks newline JSON-RPC without importing server internals', async () => {
  await withTempDirectory(async (directory) => {
    const bridgeEntry = path.join(directory, 'fake-bridge.mjs');
    await writeFile(bridgeEntry, fakeBridgeSource, { mode: 0o600 });
    const bridge = new BridgeProcess({
      bridgeEntry,
      env: {},
      label: 'unit bridge',
      captureDirectory: directory,
    });
    try {
      const initialized = await bridge.initialize();
      assert.equal(initialized.serverInfo.name, 'prometheus-mcp');
      const listed = await bridge.request('tools/list');
      assert.equal(listed.tools.length, 90);
      assert.deepEqual(await bridge.request('ping'), {});
    } finally {
      await bridge.close({ graceful: true });
    }
    const transcript = await readFile(
      path.join(directory, 'unit-bridge.protocol.jsonl'),
      'utf8',
    );
    for (const line of transcript.trim().split('\n')) {
      const frame = JSON.parse(line);
      assert.equal(frame.jsonrpc, '2.0');
      assert.equal(typeof frame.id, 'number');
      assert.equal(typeof frame.kind, 'string');
    }
  });
});

test('inventory and typed compatibility assertions are exact', () => {
  const expectedNames = Array.from({ length: 90 }, (_, index) =>
    index === 0 ? 'diagnostics' : `tool_${String(index).padStart(2, '0')}`);
  assert.doesNotThrow(() => assertCompatibilityInventory(
    expectedNames.map((name) => ({ name })),
    expectedNames,
  ));
  assert.throws(
    () => assertCompatibilityInventory(
      expectedNames.slice(1).map((name) => ({ name })),
      expectedNames,
    ),
    /90/u,
  );

  assert.doesNotThrow(() => assertRemovedToolResult({
    ok: false,
    error: {
      code: 'TOOL_REMOVED',
      tool: 'start_visual_session',
      removed_since: '0.9.0',
      observed_as_typed_stubs_as_of: '0.9.72',
      replacements: ['visual_reason', 'client', 'is_final'],
      recovery: 'Use per-action visual metadata.',
    },
  }));
  assert.throws(
    () => assertRemovedToolResult({
      ok: false,
      error: {
        code: 'TOOL_REMOVED',
        removed_since: '0.9.0',
        observed_absent_as_of: '0.9.72',
      },
    }),
    /observed_as_typed_stubs_as_of/u,
  );
});

test('diagnostics are the exact ten closed components', () => {
  assert.deepEqual(DIAGNOSTIC_KEYS, [
    'browser',
    'bridge',
    'active_tab',
    'content_adapter',
    'internal_adapter',
    'webui_adapter',
    'vault',
    'provider',
    'supervision',
    'extensions',
  ]);
  const components = DIAGNOSTIC_KEYS.map((key, index) => ({
    key,
    status: index < 8 ? 'ready' : 'not_ready',
    reason: 'Bounded public status.',
    next_action: 'Use the documented recovery.',
  }));
  assert.doesNotThrow(() => assertDiagnosticInventory({ ok: true, components }));
  assert.throws(
    () => assertDiagnosticInventory({ ok: true, components: components.slice(1) }),
    /ten/u,
  );
  assert.equal(RPC_TIMEOUT_MS, 30_000);
});

test('captured-output denylist rejects endpoint, session, page, reason, and profile data', () => {
  const denied = [
    'a'.repeat(64),
    'opaque-session-fixture',
    FIXTURE_PAGE_TEXT,
    'private-visual-reason',
    '/tmp/private-profile',
  ];
  assert.doesNotThrow(() => assertSafeCapturedOutput(
    'prometheus-mcp: browser heartbeat unavailable\n',
    denied,
  ));
  for (const secret of denied) {
    assert.throws(
      () => assertSafeCapturedOutput(`prefix ${secret} suffix`, denied),
      /captured output/u,
    );
  }
});

test('full protocol responses keep private data out and page data inside tool results', () => {
  const allowedPageText = 'requested fixture page text';
  const safe = [{
    method: 'tools/call',
    frame: {
      jsonrpc: '2.0',
      id: 1,
      result: { content: [{ type: 'text', text: allowedPageText }] },
    },
  }];
  assert.doesNotThrow(() => assertSafeProtocolResponses(
    safe,
    ['private-bearer'],
    [allowedPageText],
  ));
  assert.throws(
    () => assertSafeProtocolResponses(
      [{
        method: 'tools/call',
        frame: { jsonrpc: '2.0', id: 2, result: { token: 'private-bearer' } },
      }],
      ['private-bearer'],
      [allowedPageText],
    ),
    /denied private value/u,
  );
  assert.throws(
    () => assertSafeProtocolResponses(
      [{
        method: 'initialize',
        frame: { jsonrpc: '2.0', id: 3, result: { text: allowedPageText } },
      }],
      ['private-bearer'],
      [allowedPageText],
    ),
    /successful tool result/u,
  );
});

test('graceful bridge close requires a zero exit without a signal', async () => {
  await withTempDirectory(async (directory) => {
    const bridgeEntry = path.join(directory, 'nonzero-bridge.mjs');
    await writeFile(
      bridgeEntry,
      `${fakeBridgeSource}\nprocess.exitCode = 7;\n`,
      { mode: 0o600 },
    );
    const bridge = new BridgeProcess({
      bridgeEntry,
      env: {},
      label: 'nonzero bridge',
      captureDirectory: directory,
    });
    await bridge.initialize();
    await assert.rejects(
      bridge.close({ graceful: true }),
      /did not exit cleanly/u,
    );
  });
});

test('shell live gate pins the built app, descriptor mode, deadlines, and process boundary', async () => {
  const shell = await readFile(
    new URL('../smoke-browser.sh', import.meta.url),
    'utf8',
  );
  assert.match(shell, /Prometheus\.app\/Contents\/MacOS\/Prometheus/u);
  assert.match(shell, /--user-data-dir=/u);
  assert.match(shell, /--no-first-run/u);
  assert.match(shell, /--no-default-browser-check/u);
  assert.match(shell, /--prometheus-agent-endpoint-descriptor=/u);
  assert.match(shell, /--test-type=prometheus-runtime/u);
  assert.match(shell, /--prometheus-runtime-test-provider-config=/u);
  assert.match(shell, /provider-bootstrap\.json/u);
  assert.match(shell, /phase20-smoke-local/u);
  assert.match(shell, /phase20-fixture-model/u);
  assert.match(shell, /PROMETHEUS_MCP_FIXTURE_PROVIDER_DELAY_MS=5000/u);
  assert.match(shell, /kind: 'lm_studio'/u);
  assert.match(shell, /route: 'local'/u);
  assert.match(shell, /fs\.openSync\(bootstrapFile, 'wx', 0o600\)/u);
  assert.match(shell, /metadata\.isSymbolicLink\(\)/u);
  assert.match(shell, /PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR/u);
  assert.match(shell, /DESCRIPTOR_WAIT_SECONDS=20/u);
  assert.match(shell, /SMOKE_TIMEOUT_SECONDS=120/u);
  assert.match(shell, /descriptor mode is not 0600/u);
  assert.doesNotMatch(shell, /set_provider_config|prometheus\.runtime/iu);
  assert.doesNotMatch(shell, /claude|cursor|codex|terminal|agent[_ -]?cli/iu);
});
