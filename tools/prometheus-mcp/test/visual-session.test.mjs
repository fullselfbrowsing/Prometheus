import assert from 'node:assert/strict';
import test from 'node:test';

import { getToolDefinition } from '../src/catalog.mjs';
import {
  normalizeToolArguments,
  normalizeVisualClient,
  VISUAL_CLIENT_BADGES,
} from '../src/schema.mjs';

test('visual metadata is optional and preserved independently', () => {
  const action = getToolDefinition('click');
  assert.deepEqual(normalizeToolArguments(action, {}), {});
  assert.deepEqual(
    normalizeToolArguments(action, { visual_reason: 'Submit the form' }),
    { visual_reason: 'Submit the form' },
  );
  assert.deepEqual(normalizeToolArguments(action, { client: 'chat-gpt' }), {
    client: 'ChatGPT',
  });
  assert.deepEqual(normalizeToolArguments(action, { is_final: true }), {
    is_final: true,
  });
  assert.deepEqual(
    normalizeToolArguments(getToolDefinition('clear_input'), {
      visual_reason: 'Clear the field',
      client: 'open_claw-🦀',
      is_final: false,
    }),
    {
      visual_reason: 'Clear the field',
      client: 'OpenClaw 🦀',
      is_final: false,
    },
  );
});

test('all thirteen badge labels normalize deterministically', () => {
  assert.equal(VISUAL_CLIENT_BADGES.length, 13);
  assert.equal(normalizeVisualClient(), 'External Client');
  for (const badge of VISUAL_CLIENT_BADGES) {
    const variant = badge.toUpperCase().replaceAll(' ', '_');
    assert.equal(normalizeVisualClient(variant), badge);
  }
});

test('unknown badges are denied without reflecting client or reason content', () => {
  const privateLabel = 'Private Operator Label';
  const privateReason = 'private account secret';
  assert.throws(
    () => normalizeToolArguments(getToolDefinition('click'), {
      client: privateLabel,
      visual_reason: privateReason,
    }),
    (error) => {
      assert.equal(error.code, 'BADGE_NOT_ALLOWED');
      assert.doesNotMatch(error.message, new RegExp(privateLabel, 'u'));
      assert.doesNotMatch(error.message, new RegExp(privateReason, 'u'));
      return true;
    },
  );
});

test('visual field bounds are measured as UTF-8 bytes', () => {
  const action = getToolDefinition('click');
  assert.throws(
    () => normalizeToolArguments(action, { visual_reason: '🦀'.repeat(65) }),
    ({ code }) => code === 'INVALID_ARGUMENT',
  );
  assert.throws(
    () => normalizeToolArguments(action, { visual_reason: '' }),
    ({ code }) => code === 'INVALID_ARGUMENT',
  );
});
