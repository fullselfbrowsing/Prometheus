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

const makeHarness = (health) => {
  const calls = [];
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
  return { calls, handler: createToolHandler({ session }) };
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

test('compatibility disposition is selected before argument normalization', async () => {
  const { calls, handler } = makeHarness();
  const legacyArguments = {
    retired_field: { deeply: ['legacy', 42] },
    visual_reason: 'must not be reflected',
  };
  for (const name of ['click_at', 'run_task', 'start_supervision_session', 'start_visual_session']) {
    for (const args of [{}, legacyArguments]) {
      const result = await handler.callTool({ name, arguments: args });
      assertParity(result, true);
      assert.equal(result.structuredContent.ok, false);
      assert.equal(result.structuredContent.error.tool, name);
      assert.ok(['UNSUPPORTED_ROUTE', 'NOT_READY', 'TOOL_REMOVED'].includes(
        result.structuredContent.error.code,
      ));
      assert.doesNotMatch(result.content[0].text, /must not be reflected/iu);
    }
  }
  assert.equal(calls.length, 0);
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
