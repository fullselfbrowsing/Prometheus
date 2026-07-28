import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import { COMPATIBILITY_CATALOG, getToolDefinition } from '../src/catalog.mjs';
import { createToolHandler } from '../src/tool-handler.mjs';

const loadFixture = async (name) => JSON.parse(
  await readFile(new URL(`fixtures/${name}`, import.meta.url), 'utf8'),
);

const frozen = await loadFixture('frozen-v1-tools.json');
const current = await loadFixture('current-fsb-tools.json');
const expectedNames = [...new Set([...frozen.names, ...current.names])].sort();

const phase20ForwardingCases = [
  ['run_task', { prompt: 'Read the page', requested_execution: 'auto' }],
  ['stop_task', { task_id: 'task-1' }],
  ['get_task_status', { task_id: 'task-1' }],
  ['list_tasks', { limit: 20 }],
  ['get_provider_config', { provider_id: 'provider-1' }],
  ['list_providers', { include_disabled: true }],
  ['discover_models', { provider_id: 'provider-1' }],
  ['get_logs', { limit: 20 }],
  ['action_history', { task_id: 'task-1', limit: 20 }],
  ['runtime_diagnostics', {}],
  ['save_memory', { title: 'Title', text: 'Safe note', tags: ['one'], shared: false }],
  ['list_memory', { limit: 20 }],
  ['save_site_guide', {
    title: 'Guide',
    instructions: 'Use the menu',
    canonical_origin: 'https://example.test',
    tags: ['one'],
    shared: true,
  }],
  ['list_site_guides', { limit: 20 }],
  ['create_vault_entry', {
    label: 'Work login',
    kind: 'credential',
    canonical_site_origin: 'https://example.test',
  }],
  ['list_vault_entries', { kind: 'credential' }],
  ['vault_autofill', { entry_id: 'vault-1' }],
  ['list_sessions', { limit: 20 }],
  ['get_session_detail', { run_id: 'task-1' }],
  ['search_memory', { query: 'menu', limit: 20 }],
  ['get_memory_stats', {}],
  ['get_site_guide', { guide_id: 'guide-1' }],
  ['list_credentials', { limit: 20 }],
  ['fill_credential', { entry_id: 'vault-1' }],
  ['list_payment_methods', { limit: 20 }],
  ['use_payment_method', { entry_id: 'vault-2' }],
];

const phase20AliasCases = [
  ['submit_task', 'run_task', { prompt: 'Read the page', requested_execution: 'auto' }],
  ['cancel_task', 'stop_task', { task_id: 'task-1' }],
  ['task_status', 'get_task_status', { task_id: 'task-1' }],
  ['list_runtime_logs', 'get_logs', { limit: 20 }],
];

const makeHarness = (health, options = {}) => {
  const calls = [];
  const diagnostics = [];
  const session = {
    command: async (route, envelope, { signal } = {}) => {
      calls.push({ route, envelope, signal });
      return {
        ok: true,
        error_code: 'NONE',
        route,
        echoed: envelope,
      };
    },
    health: async () => health ?? {
      ok: true,
      diagnostics: [
        { key: 'browser', status: 'ready' },
        { key: 'bridge', status: 'ready' },
        { key: 'active_tab', status: 'ready' },
        { key: 'content_adapter', status: 'ready' },
        { key: 'internal_adapter', status: 'ready' },
        { key: 'webui_adapter', status: 'ready' },
        { key: 'vault', status: 'not_ready' },
        { key: 'provider', status: 'not_ready' },
        { key: 'supervision', status: 'not_ready' },
        { key: 'extensions', status: 'not_ready' },
      ],
    },
  };
  return {
    calls,
    diagnostics,
    handler: createToolHandler({
      session,
      diagnostic: (message) => diagnostics.push(message),
      ...options,
    }),
  };
};

const assertParity = (result, isError) => {
  assert.equal(result.isError, isError);
  assert.deepEqual(result.content, [
    { type: 'text', text: JSON.stringify(result.structuredContent) },
  ]);
  assert.deepEqual(JSON.parse(result.content[0].text), result.structuredContent);
};

test('tools/list exposes the exact 90-name fixture union once', () => {
  const { handler } = makeHarness();
  const tools = handler.listTools();
  assert.equal(tools.length, 90);
  assert.equal(new Set(tools.map(({ name }) => name)).size, 90);
  assert.deepEqual(tools.map(({ name }) => name).sort(), expectedNames);
  for (const tool of tools) {
    assert.deepEqual(Object.keys(tool).sort(), ['description', 'inputSchema', 'name']);
    assert.equal(tool.inputSchema.additionalProperties, false, tool.name);
    assert.equal(Object.hasOwn(tool, 'disposition'), false);
  }
});

test('native tools and all eight aliases forward only canonical routes', async () => {
  const { calls, handler } = makeHarness();
  const cases = [
    ['list_tabs', 'list_tabs', {}],
    ['new_tab', 'open_tab', { url: 'https://example.test/', foreground: false }],
    ['switch_tab', 'activate_tab', { tabId: '7', client: 'codex' }],
    ['refresh', 'reload', { tabIndex: '0' }],
    ['back', 'go_back', {}],
    ['type', 'type_text', { selector: '#name', text: 'Ada' }],
    ['press_enter', 'press_key', { selector: '#name' }],
    ['select', 'select_option', { selector: '#choice', option_value: 'one' }],
    ['clear_input', 'clear', { selector: '#name' }],
  ];
  for (const [name, route, args] of cases) {
    const result = await handler.callTool({ name, arguments: args });
    assertParity(result, false);
    assert.equal(calls.at(-1).route, route);
  }
  assert.equal(calls.length, cases.length);
  assert.deepEqual(calls[2].envelope, {
    target: { tab_id: 7 },
    visual: { client: 'Codex' },
    params: {},
  });
  assert.deepEqual(calls[1].envelope, {
    target: {},
    params: { url: 'https://example.test/', foreground: false },
    visual: {},
  });
  assert.deepEqual(calls[3].envelope.target, { tabIndex: 0 });
  assert.deepEqual(calls[5].envelope.params, {
    element: { selector: '#name' },
    text: 'Ada',
  });
  assert.deepEqual(calls[6].envelope.params, {
    element: { selector: '#name' },
    key: 'Enter',
  });
  assert.equal(
    COMPATIBILITY_CATALOG.some(({ nativeRoute }) => nativeRoute === 'clear_input'),
    false,
  );
});

test('unavailable stub and removed dispositions are selected before argument normalization', async () => {
  const { calls, handler } = makeHarness();
  const legacyArguments = {
    retired_field: { deeply: ['legacy', 42] },
    visual_reason: 'must not be reflected',
  };
  for (const name of ['click_at', 'start_visual_session']) {
    for (const args of [{}, legacyArguments]) {
      const result = await handler.callTool({ name, arguments: args });
      assertParity(result, true);
      assert.equal(result.structuredContent.ok, false);
      assert.equal(result.structuredContent.error.tool, name);
      assert.ok(['UNSUPPORTED_ROUTE', 'TOOL_REMOVED'].includes(
        result.structuredContent.error.code,
      ));
      assert.doesNotMatch(result.content[0].text, /must not be reflected/iu);
    }
  }
  assert.equal(calls.length, 0);
});

test('all 26 externally callable canonical runtime routes forward once', async () => {
  const { calls, handler } = makeHarness();
  assert.equal(phase20ForwardingCases.length, 26);
  for (const [name, arguments_] of phase20ForwardingCases) {
    const result = await handler.callTool({ name, arguments: arguments_ });
    assertParity(result, false);
    assert.equal(calls.at(-1).route, name, name);
    assert.deepEqual(calls.at(-1).envelope, { params: arguments_ }, name);
  }
  assert.equal(calls.length, phase20ForwardingCases.length);
});

test('the four Phase 20 aliases are behaviorally identical to canonical routes', async () => {
  assert.equal(phase20AliasCases.length, 4);
  for (const [alias, canonical, arguments_] of phase20AliasCases) {
    const aliasHarness = makeHarness();
    const canonicalHarness = makeHarness();
    const aliasResult = await aliasHarness.handler.callTool({
      name: alias,
      arguments: arguments_,
    });
    const canonicalResult = await canonicalHarness.handler.callTool({
      name: canonical,
      arguments: arguments_,
    });
    assert.deepEqual(aliasResult, canonicalResult, alias);
    assert.deepEqual(aliasHarness.calls, canonicalHarness.calls, alias);
    assert.equal(aliasHarness.calls[0].route, canonical, alias);
  }
});

test('external provider mutation is denied before normalization or transport', async () => {
  const normalizationCalls = [];
  const sentinel = 'phase20-provider-secret-sentinel-never-echo';
  const { calls, diagnostics, handler } = makeHarness(undefined, {
    normalizeArguments: (...args) => {
      normalizationCalls.push(args);
      throw new Error(`normalizer must not inspect ${sentinel}`);
    },
  });
  const inputs = [
    { provider_id: 'provider-1', endpoint: 'https://endpoint-sentinel.test/v1' },
    { provider_id: 'provider-1', route_class: 'local' },
    { provider_id: 'provider-1', fallback_rank: 1 },
    {
      provider_id: 'provider-1',
      input_rate_microunits: 25,
      output_rate_microunits: 50,
    },
    { provider_id: 'provider-1', enabled: true, trusted: true },
    { provider_id: 'provider-1', unknown_metadata: 'must-not-be-inspected' },
    { provider_id: 'provider-1', api_key: sentinel },
    { provider_id: 'provider-1', nested: [{ password: sentinel }] },
  ];
  const serializedResults = [];
  for (const arguments_ of inputs) {
    const result = await handler.callTool({
      name: 'set_provider_config',
      arguments: arguments_,
    });
    assertParity(result, true);
    assert.equal(result.structuredContent.error.code, 'LOCAL_UI_REQUIRED');
    assert.match(result.structuredContent.error.recovery, /local control panel/iu);
    serializedResults.push(JSON.stringify(result));
  }
  assert.equal(new Set(serializedResults).size, 1);
  assert.equal(normalizationCalls.length, 0);
  assert.equal(calls.length, 0);
  assert.deepEqual(diagnostics, []);
  const observable = JSON.stringify({ serializedResults, diagnostics });
  assert.doesNotMatch(observable, new RegExp(sentinel, 'u'));
  assert.doesNotMatch(observable, /endpoint-sentinel|must-not-be-inspected/iu);
});

test('runtime caller authority and recursive secrets never reach native transport', async () => {
  const { calls, handler } = makeHarness();
  const authority = await handler.callTool({
    name: 'run_task',
    arguments: {
      prompt: 'Read the page',
      requested_execution: 'auto',
      caller_id: 'forged-caller',
    },
  });
  assertParity(authority, true);
  assert.equal(authority.structuredContent.error.code, 'INVALID_ARGUMENT');

  const sentinel = 'phase20-recursive-secret-sentinel';
  const secret = await handler.callTool({
    name: 'save_memory',
    arguments: {
      title: 'Title',
      text: 'Safe note',
      unknown: [{ authorization: sentinel }],
    },
  });
  assertParity(secret, true);
  assert.equal(secret.structuredContent.error.code, 'SECRET_TRANSPORT_BLOCKED');
  assert.doesNotMatch(JSON.stringify(secret), new RegExp(sentinel, 'u'));
  assert.equal(calls.length, 0);
});

test('read-only model discovery stays live and forwards its bounded metadata', async () => {
  const { calls, handler } = makeHarness();
  const started = await handler.callTool({
    name: 'discover_models',
    arguments: { provider_id: 'provider-1' },
  });
  assertParity(started, false);
  const completed = await handler.callTool({
    name: 'discover_models',
    arguments: { operation_id: '17' },
  });
  assertParity(completed, false);
  assert.equal(calls.length, 2);
  assert.equal(calls[0].route, 'discover_models');
  assert.deepEqual(calls[0].envelope, {
    params: { provider_id: 'provider-1' },
  });
  assert.equal(calls[1].route, 'discover_models');
  assert.deepEqual(calls[1].envelope, {
    params: { operation_id: '17' },
  });
});

test('every non-native catalog disposition returns a truthful local error', async () => {
  const { calls, handler } = makeHarness();
  const local = COMPATIBILITY_CATALOG.filter(({ disposition }) =>
    ['typed_stub', 'later_phase', 'removed'].includes(disposition));
  assert.ok(local.length > 0);
  for (const definition of local) {
    const result = await handler.callTool({
      name: definition.name,
      arguments: { legacy: 'ignored-before-normalization' },
    });
    assertParity(result, true);
    assert.equal(result.structuredContent.error.tool, definition.name);
    assert.ok(result.structuredContent.error.recovery.length > 0);
  }
  assert.equal(calls.length, 0);
});

test('native validation normalizes declared numbers and rejects unknown fields', async () => {
  const { calls, handler } = makeHarness();
  const result = await handler.callTool({
    name: 'read_page',
    arguments: { tabIndex: '0', max_chars: '1e2', max_nodes: '42.0' },
  });
  assertParity(result, false);
  assert.deepEqual(calls[0].envelope, {
    target: { tabIndex: 0 },
    params: { max_chars: 100, max_nodes: 42 },
    visual: {},
  });

  for (const arguments_ of [
    { max_chars: 'NaN' },
    { tab_id: 1, tabIndex: 0 },
    { arbitrary_route: 'execute_js' },
  ]) {
    const failure = await handler.callTool({ name: 'read_page', arguments: arguments_ });
    assertParity(failure, true);
    assert.ok(['INVALID_ARGUMENT', 'INVALID_TARGET'].includes(
      failure.structuredContent.error.code,
    ));
  }
  assert.equal(calls.length, 1);
});

test('extension surface selectors reach only the native target envelope', async () => {
  const { calls, handler } = makeHarness();
  for (const extension_surface of ['popup', 'side_panel']) {
    const result = await handler.callTool({
      name: 'read_page',
      arguments: { tab_id: 17, extension_surface, max_chars: 200 },
    });
    assertParity(result, false);
    assert.deepEqual(calls.at(-1).envelope, {
      target: { tab_id: 17, extension_surface },
      params: { max_chars: 200 },
      visual: {},
    });
  }
  for (const arguments_ of [
    { extension_surface: 'popup' },
    { tabIndex: 0, extension_surface: 'popup' },
    { tabId: 17, extension_surface: 'side_panel' },
    { tab_id: 17, extension_surface: 'background' },
    { tab_id: 17, extension_surface: ['popup', 'side_panel'] },
    { tab_id: 17, extension_surface: 'popup', extension_id: 'chosen' },
  ]) {
    const result = await handler.callTool({
      name: 'read_page',
      arguments: arguments_,
    });
    assertParity(result, true);
    assert.ok(['INVALID_ARGUMENT', 'INVALID_TARGET'].includes(
      result.structuredContent.error.code,
    ));
  }
  assert.equal(calls.length, 2);
});

test('open_internal_surface forwards only its closed three-value enum', async () => {
  const { calls, handler } = makeHarness();
  for (const surface of ['new_tab', 'side_panel', 'control_panel']) {
    const result = await handler.callTool({
      name: 'open_internal_surface',
      arguments: { surface },
    });
    assertParity(result, false);
    assert.equal(calls.at(-1).route, 'open_internal_surface');
    assert.deepEqual(calls.at(-1).envelope.params, { surface });
  }
  for (const surface of ['chrome://settings', 'arbitrary_route']) {
    const result = await handler.callTool({
      name: 'open_internal_surface',
      arguments: { surface },
    });
    assertParity(result, true);
    assert.equal(result.structuredContent.error.code, 'INVALID_ARGUMENT');
  }
  assert.equal(calls.length, 3);
});

test('element, frame, attribute, and scroll arguments match the native codec', async () => {
  const { calls, handler } = makeHarness();
  const attribute = await handler.callTool({
    name: 'get_attribute',
    arguments: {
      tab_id: 11,
      ref: 'node-4',
      selector: '#fallback',
      document_token: 'document-9',
      attribute: 'aria-label',
    },
  });
  assertParity(attribute, false);
  assert.deepEqual(calls[0].envelope, {
    target: { tab_id: 11 },
    visual: {},
    params: {
      element: { element_ref: 'node-4', selector: '#fallback' },
      frame: { document_token: 'document-9' },
      attribute_name: 'aria-label',
    },
  });

  const scroll = await handler.callTool({
    name: 'scroll',
    arguments: {
      tabIndex: '0',
      selector: 'main',
      delta_x: '-20',
      delta_y: '400',
    },
  });
  assertParity(scroll, false);
  assert.deepEqual(calls[1].envelope, {
    target: { tabIndex: 0 },
    visual: {},
    params: {
      element: { selector: 'main' },
      scroll_delta_x: -20,
      scroll_delta_y: 400,
    },
  });
  for (const envelope of calls.map(({ envelope }) => envelope)) {
    for (const flatField of [
      'ref',
      'selector',
      'document_token',
      'attribute',
      'delta_x',
      'delta_y',
    ]) {
      assert.equal(Object.hasOwn(envelope.params, flatField), false, flatField);
    }
  }
});

test('execute_js forwards the browser permission and mutation-verification contract', async () => {
  const calls = [];
  const handler = createToolHandler({
    session: {
      command: async (route, envelope) => {
        calls.push({ route, envelope });
        if (envelope.params.javascript_permission_granted !== true) {
          return {
            ok: false,
            error_code: 'PERMISSION_BLOCKED',
            message: 'JavaScript permission is required.',
            recovery: 'Explicitly grant JavaScript permission and retry.',
          };
        }
        return { ok: true };
      },
    },
  });

  const absent = await handler.callTool({
    name: 'execute_js',
    arguments: { javascript: 'document.title' },
  });
  assertParity(absent, true);
  assert.equal(absent.structuredContent.error_code, 'PERMISSION_BLOCKED');
  assert.deepEqual(calls[0].envelope.params, { javascript: 'document.title' });
  assert.equal(
    Object.hasOwn(calls[0].envelope.params, 'javascript_permission_granted'),
    false,
  );

  const denied = await handler.callTool({
    name: 'execute_js',
    arguments: {
      javascript: 'document.title',
      javascript_permission_granted: false,
    },
  });
  assertParity(denied, true);
  assert.deepEqual(calls[1].envelope.params, {
    javascript: 'document.title',
    javascript_permission_granted: false,
  });

  const allowed = await handler.callTool({
    name: 'execute_js',
    arguments: {
      javascript: 'document.body.dataset.ready = "yes"',
      javascript_permission_granted: true,
      verify_mutation: true,
    },
  });
  assertParity(allowed, false);
  assert.equal(calls[2].route, 'execute_js');
  assert.deepEqual(calls[2].envelope, {
    target: {},
    visual: {},
    params: {
      javascript: 'document.body.dataset.ready = "yes"',
      javascript_permission_granted: true,
      verify_mutation: true,
    },
  });

  const invalid = await handler.callTool({
    name: 'execute_js',
    arguments: {
      javascript: 'document.title',
      javascript_permission_granted: 'yes',
    },
  });
  assertParity(invalid, true);
  assert.equal(invalid.structuredContent.error.code, 'INVALID_ARGUMENT');
  assert.equal(calls.length, 3);
});

test('unknown tools and malformed calls are stable tool failures', async () => {
  const { calls, handler } = makeHarness();
  for (const call of [
    { name: 'not_a_tool', arguments: {} },
    { name: 7, arguments: {} },
    { name: 'list_tabs', arguments: [] },
  ]) {
    const result = await handler.callTool(call);
    assertParity(result, true);
    assert.ok(['UNKNOWN_TOOL', 'INVALID_ARGUMENT'].includes(
      result.structuredContent.error.code,
    ));
  }
  assert.equal(calls.length, 0);
});
