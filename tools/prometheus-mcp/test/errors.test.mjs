import assert from 'node:assert/strict';
import test from 'node:test';

import { getToolDefinition } from '../src/catalog.mjs';
import { compatibilityError } from '../src/errors.mjs';

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

test('later-phase failures state their owner and recovery', () => {
  for (const [name, owner] of [
    ['run_task', 20],
    ['start_supervision_session', 21],
  ]) {
    const result = compatibilityError(getToolDefinition(name));
    assert.equal(result.ok, false);
    assert.equal(result.error.code, 'NOT_READY');
    assert.equal(result.error.owner_phase, owner);
    assert.ok(result.error.recovery.length > 0);
  }
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
