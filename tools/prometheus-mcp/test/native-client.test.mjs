import assert from 'node:assert/strict';
import { chmod, mkdtemp, rm, symlink, unlink, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';

import {
  defaultDescriptorPath,
  MAX_NATIVE_RESPONSE_BYTES,
  NativeClient,
  NativeClientError,
  readEndpointDescriptor,
  resolveDescriptorPath,
} from '../src/native-client.mjs';
import { BrowserSession, HEARTBEAT_INTERVAL_MS } from '../src/session.mjs';

const descriptorFor = (endpoint, overrides = {}) => ({
  protocol: 'prometheus-agent-v1',
  endpoint,
  pid: 4242,
  instance_nonce: 'a'.repeat(64),
  bearer: 'b'.repeat(64),
  ...overrides,
});

const withTempDirectory = async (callback) => {
  const directory = await mkdtemp(path.join(tmpdir(), 'prometheus-mcp-node-test-'));
  try {
    return await callback(directory);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
};

const writeDescriptor = async (file, descriptor, mode = 0o600) => {
  await writeFile(file, JSON.stringify(descriptor), { mode });
  await chmod(file, mode);
};

const startGateway = async () => {
  const requests = [];
  const server = createServer((request, response) => {
    const chunks = [];
    request.on('data', (chunk) => chunks.push(chunk));
    request.on('end', () => {
      const bodyText = Buffer.concat(chunks).toString('utf8');
      requests.push({
        method: request.method,
        path: request.url,
        authorization: request.headers.authorization,
        contentType: request.headers['content-type'],
        body: bodyText.length > 0 ? JSON.parse(bodyText) : undefined,
      });
      let payload = { ok: true };
      if (request.url === '/v1/session/create' || request.url === '/v1/session/resume') {
        payload = { ok: true, session_id: 'browser-session-1', reconnect_grace_ms: 10_000 };
      }
      if (request.url === '/v1/health') {
        payload = { ok: true, diagnostics: [] };
      }
      const serialized = JSON.stringify(payload);
      response.writeHead(200, {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(serialized),
      });
      response.end(serialized);
    });
  });
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  const address = server.address();
  return {
    endpoint: `http://127.0.0.1:${address.port}`,
    requests,
    close: () => new Promise((resolve, reject) =>
      server.close((error) => error ? reject(error) : resolve())),
  };
};

test('descriptor discovery uses the exact temp child and absolute override only', () => {
  assert.equal(
    defaultDescriptorPath(),
    path.join(tmpdir(), 'prometheus-mcp', 'endpoint.json'),
  );
  assert.equal(resolveDescriptorPath({}), defaultDescriptorPath());
  assert.equal(
    resolveDescriptorPath({ PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: '/tmp/custom-endpoint.json' }),
    '/tmp/custom-endpoint.json',
  );
  assert.throws(
    () => resolveDescriptorPath({ PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: 'relative.json' }),
    (error) => error instanceof NativeClientError && error.code === 'DESCRIPTOR_INVALID',
  );
});

test('descriptor validation requires a regular owner-only loopback contract', async () => {
  await withTempDirectory(async (directory) => {
    const file = path.join(directory, 'endpoint.json');
    const valid = descriptorFor('http://127.0.0.1:43119');
    await writeDescriptor(file, valid);
    assert.deepEqual(
      await readEndpointDescriptor({ PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file }),
      valid,
    );

    const invalid = [
      { protocol: 'wrong' },
      { endpoint: 'http://localhost:43119' },
      { endpoint: 'https://127.0.0.1:43119' },
      { endpoint: 'http://127.0.0.1:43119/path' },
      { endpoint: 'http://user:pass@127.0.0.1:43119' },
      { endpoint: 'http://127.0.0.1:43119?query=1' },
      { endpoint: 'http://127.0.0.1:43119#fragment' },
      { pid: 0 },
      { instance_nonce: '' },
      { instance_nonce: 'not-hex' },
      { bearer: '' },
      { bearer: 'not-hex' },
      { unexpected: true },
    ];
    for (const override of invalid) {
      await writeDescriptor(file, { ...valid, ...override });
      await assert.rejects(
        readEndpointDescriptor({ PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file }),
        (error) => error.code === 'DESCRIPTOR_INVALID',
      );
    }

    await writeDescriptor(file, valid, 0o644);
    await assert.rejects(
      readEndpointDescriptor({ PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file }),
      (error) => error.code === 'DESCRIPTOR_INSECURE',
    );

    const realFile = path.join(directory, 'real-endpoint.json');
    await writeDescriptor(realFile, valid);
    await unlink(file);
    await symlink(realFile, file);
    await assert.rejects(
      readEndpointDescriptor({ PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file }),
      (error) => error.code === 'DESCRIPTOR_INVALID',
    );
  });
});

test('bearer and JSON boundaries apply to all six native endpoints', async () => {
  const gateway = await startGateway();
  try {
    await withTempDirectory(async (directory) => {
      const file = path.join(directory, 'endpoint.json');
      const descriptor = descriptorFor(gateway.endpoint);
      await writeDescriptor(file, descriptor);
      const client = new NativeClient({
        env: { PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file },
      });
      await client.createSession('fixture client');
      await client.resumeSession('browser-session-1');
      await client.touchSession('browser-session-1');
      await client.closeSession('browser-session-1');
      await client.command('browser-session-1', 'list_tabs', {
        target: {},
        params: {},
        visual: {},
      });
      await client.health();

      assert.deepEqual(
        gateway.requests.map(({ method, path: requestPath }) => `${method} ${requestPath}`),
        [
          'POST /v1/session/create',
          'POST /v1/session/resume',
          'POST /v1/session/touch',
          'POST /v1/session/close',
          'POST /v1/agent/command',
          'GET /v1/health',
        ],
      );
      for (const request of gateway.requests) {
        assert.equal(request.authorization, `Bearer ${descriptor.bearer}`);
        if (request.method === 'POST') {
          assert.equal(request.contentType, 'application/json');
        }
      }
      assert.deepEqual(gateway.requests[4].body, {
        route: 'list_tabs',
        session_id: 'browser-session-1',
        target: {},
        params: {},
        visual: {},
      });
    });
  } finally {
    await gateway.close();
  }
});

test('session initialization creates from a bounded label or resumes only an explicit id', async () => {
  const calls = [];
  const nativeClient = {
    createSession: async (displayLabel) => {
      calls.push(['create', displayLabel]);
      return { ok: true, session_id: 'created-session' };
    },
    resumeSession: async (sessionId) => {
      calls.push(['resume', sessionId]);
      return { ok: true, session_id: sessionId };
    },
    touchSession: async () => ({ ok: true }),
    closeSession: async () => ({ ok: true }),
  };
  const timers = { setInterval: () => ({ unref() {} }), clearInterval() {} };

  const created = new BrowserSession({ nativeClient, env: {}, ...timers });
  await created.initialize({ name: '\ud83e\udd80'.repeat(40), version: '1' });
  assert.equal(created.sessionId, 'created-session');
  assert.equal(calls[0][0], 'create');
  assert.ok(Buffer.byteLength(calls[0][1], 'utf8') <= 80);

  const resumed = new BrowserSession({
    nativeClient,
    env: { PROMETHEUS_MCP_RESUME_SESSION_ID: 'opaque-resume-id' },
    ...timers,
  });
  await resumed.initialize({ name: 'same display label', version: '1' });
  assert.equal(resumed.sessionId, 'opaque-resume-id');
  assert.deepEqual(calls[1], ['resume', 'opaque-resume-id']);
  assert.equal(calls.filter(([kind]) => kind === 'create').length, 1);
});

test('heartbeat is exactly three seconds and graceful close occurs once', async () => {
  const calls = [];
  let timer;
  let cleared = false;
  const nativeClient = {
    createSession: async () => ({ ok: true, session_id: 'heartbeat-session' }),
    touchSession: async (id) => { calls.push(['touch', id]); return { ok: true }; },
    closeSession: async (id) => { calls.push(['close', id]); return { ok: true }; },
  };
  const session = new BrowserSession({
    nativeClient,
    env: {},
    setInterval: (callback, milliseconds) => {
      timer = { callback, milliseconds, unref() {} };
      return timer;
    },
    clearInterval: (value) => { assert.equal(value, timer); cleared = true; },
  });
  await session.initialize({ name: 'heartbeat test' });
  assert.equal(HEARTBEAT_INTERVAL_MS, 3_000);
  assert.equal(timer.milliseconds, 3_000);
  await timer.callback();
  assert.deepEqual(calls, [['touch', 'heartbeat-session']]);
  await session.shutdown({ graceful: true });
  await session.shutdown({ graceful: true });
  assert.equal(cleared, true);
  assert.deepEqual(calls, [
    ['touch', 'heartbeat-session'],
    ['close', 'heartbeat-session'],
  ]);
});

test('abrupt shutdown stops heartbeat without closing browser authority', async () => {
  let closes = 0;
  let clears = 0;
  const session = new BrowserSession({
    nativeClient: {
      createSession: async () => ({ ok: true, session_id: 'grace-session' }),
      touchSession: async () => ({ ok: true }),
      closeSession: async () => { closes += 1; },
    },
    env: {},
    setInterval: () => ({ unref() {} }),
    clearInterval: () => { clears += 1; },
  });
  await session.initialize({ name: 'abrupt test' });
  await session.shutdown({ graceful: false });
  assert.equal(clears, 1);
  assert.equal(closes, 0);
});

test('connection loss rediscovers once after descriptor nonce rotation', async () => {
  await withTempDirectory(async (directory) => {
    const file = path.join(directory, 'endpoint.json');
    const first = descriptorFor('http://127.0.0.1:41001', {
      instance_nonce: 'c'.repeat(64),
      bearer: 'd'.repeat(64),
    });
    const second = descriptorFor('http://127.0.0.1:41002', {
      instance_nonce: 'e'.repeat(64),
      bearer: 'f'.repeat(64),
    });
    await writeDescriptor(file, first);
    const calls = [];
    const client = new NativeClient({
      env: { PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file },
      fetch: async (url, options) => {
        calls.push({ url, authorization: options.headers.Authorization });
        if (calls.length === 1) {
          await writeDescriptor(file, second);
          throw new TypeError('connection refused');
        }
        return new Response(JSON.stringify({ ok: true }), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        });
      },
    });
    assert.deepEqual(await client.touchSession('opaque-session'), { ok: true });
    assert.deepEqual(calls, [
      { url: 'http://127.0.0.1:41001/v1/session/touch', authorization: `Bearer ${'d'.repeat(64)}` },
      { url: 'http://127.0.0.1:41002/v1/session/touch', authorization: `Bearer ${'f'.repeat(64)}` },
    ]);
  });
});

test('command authority fields cannot be injected through the native envelope', async () => {
  let fetches = 0;
  const client = new NativeClient({
    env: { PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: '/missing/descriptor.json' },
    fetch: async () => { fetches += 1; },
  });
  for (const envelope of [
    { route: 'execute_js' },
    { session_id: 'attacker-session' },
    { target: 'not-an-object' },
    { params: [], visual: {} },
  ]) {
    await assert.rejects(
      client.command('browser-session', 'list_tabs', envelope),
      (error) => error.code === 'NATIVE_RESPONSE_INVALID',
    );
  }
  for (const operation of [
    () => client.createSession('label', { body: { display_label: 'attacker' } }),
    () => client.resumeSession('browser-session', { body: { session_id: 'attacker' } }),
    () => client.touchSession('browser-session', { method: 'GET' }),
    () => client.closeSession('browser-session', { body: {} }),
    () => client.health({ method: 'POST' }),
  ]) {
    await assert.rejects(operation(), (error) => error.code === 'CONFIG_INVALID');
  }
  assert.equal(fetches, 0);
});

test('timeouts and caller cancellation abort native fetch', async () => {
  await withTempDirectory(async (directory) => {
    const file = path.join(directory, 'endpoint.json');
    await writeDescriptor(file, descriptorFor('http://127.0.0.1:41003'));
    let timeoutAborted = false;
    const timeoutClient = new NativeClient({
      env: {
        PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file,
        PROMETHEUS_MCP_REQUEST_TIMEOUT_MS: '1000',
      },
      fetch: (_url, { signal }) => new Promise((_resolve, reject) => {
        signal.addEventListener('abort', () => {
          timeoutAborted = true;
          reject(new DOMException('timed out', 'AbortError'));
        }, { once: true });
      }),
      setTimeout: (callback) => { queueMicrotask(callback); return 1; },
      clearTimeout: () => {},
    });
    await assert.rejects(
      timeoutClient.health(),
      (error) => error.code === 'NATIVE_TIMEOUT',
    );
    assert.equal(timeoutAborted, true);

    let callerAborted = false;
    let markStarted;
    const started = new Promise((resolve) => { markStarted = resolve; });
    const cancelledClient = new NativeClient({
      env: { PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file },
      fetch: (_url, { signal }) => new Promise((_resolve, reject) => {
        markStarted();
        signal.addEventListener('abort', () => {
          callerAborted = true;
          reject(new DOMException('cancelled', 'AbortError'));
        }, { once: true });
      }),
    });
    const controller = new AbortController();
    const pending = cancelledClient.health({ signal: controller.signal });
    await started;
    controller.abort();
    await assert.rejects(pending, (error) => error.code === 'NATIVE_CANCELLED');
    assert.equal(callerAborted, true);
  });
});

test('HTTP, non-JSON, oversized, and typed failures are bounded without mutation retry', async () => {
  await withTempDirectory(async (directory) => {
    const file = path.join(directory, 'endpoint.json');
    const descriptor = descriptorFor('http://127.0.0.1:41004', {
      bearer: '1'.repeat(64),
    });
    await writeDescriptor(file, descriptor);
    for (const [response, code] of [
      [new Response('unauthorized private detail', { status: 401 }), 'NATIVE_HTTP_ERROR'],
      [new Response('not json', { status: 200 }), 'NATIVE_RESPONSE_INVALID'],
      [new Response('x'.repeat(MAX_NATIVE_RESPONSE_BYTES + 1), { status: 200 }), 'NATIVE_RESPONSE_TOO_LARGE'],
    ]) {
      let attempts = 0;
      const client = new NativeClient({
        env: { PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file },
        fetch: async () => { attempts += 1; return response; },
      });
      await assert.rejects(client.touchSession('private-session-id'), (error) => {
        assert.equal(error.code, code);
        assert.doesNotMatch(error.message, /private|unauthorized detail/iu);
        return true;
      });
      assert.equal(attempts, 1);
    }

    const typed = {
      ok: false,
      error_code: 'TAB_NOT_OWNED',
      message: 'bounded native failure',
      recovery: 'use an owned tab',
    };
    const client = new NativeClient({
      env: { PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: file },
      fetch: async () => new Response(JSON.stringify(typed), { status: 200 }),
    });
    assert.deepEqual(await client.command('private-session-id', 'navigate', {}), typed);
  });
});
