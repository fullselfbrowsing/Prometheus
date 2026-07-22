import assert from 'node:assert/strict';
import test from 'node:test';

import { getToolDefinition } from '../src/catalog.mjs';
import { compatibilityError } from '../src/errors.mjs';
import { createToolHandler } from '../src/tool-handler.mjs';

const phase21SupervisionNames = [
  'create_supervision_pairing',
  'start_supervision_session',
  'get_supervision_snapshot',
  'get_supervision_diff',
  'end_supervision_session',
];

test('typed stubs return stable nonempty compatibility failures', () => {
  const result = compatibilityError(getToolDefinition('click_at'));
  assert.deepEqual(result, {
    ok: false,
    error: {
      code: 'UNSUPPORTED_ROUTE',
      tool: 'click_at',
      owner_phase: null,
      replacements: ['click'],
      recovery: 'Use click with a stable element or tab target.',
    },
  });
});

test('native supervision forwarding uses empty browser-scoped envelopes', async () => {
  const calls = [];
  const handler = createToolHandler({
    session: {
      command: async (route, envelope) => {
        calls.push({ route, envelope });
        return { ok: true, supervision: { state: 'safe' } };
      },
    },
  });

  for (const name of phase21SupervisionNames) {
    const result = await handler.callTool({ name, arguments: {} });
    assert.equal(result.isError, false, name);
    assert.deepEqual(result.structuredContent, {
      ok: true,
      supervision: { state: 'safe' },
    }, name);
  }
  assert.deepEqual(
    calls,
    phase21SupervisionNames.map((name) => ({
      route: name,
      envelope: { target: {}, params: {}, visual: {} },
    })),
  );
});

test('native supervision forwarding sanitizes thrown native failures', async () => {
  const sentinel = 'phase21-private-bearer-session-content';
  const calls = [];
  const diagnostics = [];
  const handler = createToolHandler({
    session: {
      command: async (route, envelope) => {
        calls.push({ route, envelope });
        throw new Error(`${sentinel}:${route}`);
      },
    },
    diagnostic: (message) => diagnostics.push(String(message)),
  });

  for (const name of phase21SupervisionNames) {
    const result = await handler.callTool({ name, arguments: {} });
    assert.equal(result.isError, true, name);
    assert.deepEqual(result.structuredContent, {
      ok: false,
      error: {
        code: 'NATIVE_UNAVAILABLE',
        recovery: 'Confirm Prometheus is running and retry.',
      },
    }, name);
    assert.doesNotMatch(JSON.stringify(result), new RegExp(sentinel, 'u'), name);
  }
  assert.deepEqual(calls.map(({ route }) => route), phase21SupervisionNames);
  assert.deepEqual(
    new Set(diagnostics),
    new Set(['native request unavailable']),
  );
  assert.doesNotMatch(JSON.stringify(diagnostics), new RegExp(sentinel, 'u'));
});

test('removed visual-session calls include stable migration metadata', () => {
  for (const name of ['start_visual_session', 'end_visual_session']) {
    const { error } = compatibilityError(getToolDefinition(name));
    assert.equal(error.code, 'TOOL_REMOVED');
    assert.equal(error.removed_since, '0.9.0');
    assert.equal(error.observed_as_typed_stubs_as_of, '0.9.72');
    assert.deepEqual(error.replacements, ['visual_reason', 'client', 'is_final']);
    assert.ok(error.recovery.length > 0);
  }
});

test('native and alias tools cannot be rendered as compatibility errors', () => {
  for (const name of ['clear', 'clear_input']) {
    assert.throws(
      () => compatibilityError(getToolDefinition(name)),
      /non-native compatibility entry/,
    );
  }
});

test('native typed failures remain MCP tool results with exact text parity', async () => {
  const handler = createToolHandler({
    session: {
      command: async () => ({
        ok: false,
        error_code: 'TAB_NOT_OWNED',
        message: 'The target is not owned by this session.',
        recovery: 'Use a tab opened by this session.',
      }),
    },
  });
  const result = await handler.callTool({
    name: 'navigate',
    arguments: { tab_id: 8, url: 'https://example.test/' },
  });
  assert.equal(result.isError, true);
  assert.deepEqual(JSON.parse(result.content[0].text), result.structuredContent);
  assert.equal(result.structuredContent.error_code, 'TAB_NOT_OWNED');
});

test('thrown native failures become sanitized stable tool errors', async () => {
  const secret = 'fixture-bearer-that-must-not-leak';
  const handler = createToolHandler({
    session: {
      command: async () => {
        throw new Error(`connection failed for ${secret}`);
      },
    },
  });
  const result = await handler.callTool({ name: 'list_tabs', arguments: {} });
  assert.equal(result.isError, true);
  assert.equal(result.structuredContent.error.code, 'NATIVE_UNAVAILABLE');
  assert.doesNotMatch(JSON.stringify(result), new RegExp(secret, 'u'));
});
