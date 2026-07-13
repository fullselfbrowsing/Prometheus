import assert from 'node:assert/strict';
import test from 'node:test';

import { getToolDefinition } from '../src/catalog.mjs';
import {
  normalizeToolArguments,
  normalizeVisualClient,
  VISUAL_CLIENT_BADGES,
} from '../src/schema.mjs';
import { createToolHandler } from '../src/tool-handler.mjs';

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

test('every optional visual-field subset survives native translation', async () => {
  const calls = [];
  const diagnostics = [];
  const handler = createToolHandler({
    session: {
      command: async (route, envelope) => {
        calls.push({ route, envelope });
        return { ok: true };
      },
    },
    diagnostic: (message) => diagnostics.push(message),
  });
  const fields = {
    visual_reason: 'Submit a private form',
    client: 'chat-gpt',
    is_final: false,
  };

  for (let mask = 0; mask < 8; mask += 1) {
    const arguments_ = { selector: '#submit' };
    const expected = {};
    const keys = Object.keys(fields);
    for (let bit = 0; bit < keys.length; bit += 1) {
      if ((mask & (1 << bit)) !== 0) {
        arguments_[keys[bit]] = fields[keys[bit]];
        expected[keys[bit]] = keys[bit] === 'client' ? 'ChatGPT' : fields[keys[bit]];
      }
    }
    const result = await handler.callTool({ name: 'click', arguments: arguments_ });
    assert.equal(result.isError, false);
    assert.deepEqual(calls.at(-1).envelope.visual, expected);
    assert.equal(Object.hasOwn(calls.at(-1).envelope.visual, 'client'), (mask & 2) !== 0);
  }
  assert.equal(calls.length, 8);
  assert.deepEqual(diagnostics, []);
});

test('aliases preserve independent visual fields without using them as identity', async () => {
  const calls = [];
  const handler = createToolHandler({
    session: {
      command: async (route, envelope) => {
        calls.push({ route, envelope });
        return { ok: true, session_id: 'must-not-be-forwarded' };
      },
    },
  });
  const result = await handler.callTool({
    name: 'clear_input',
    arguments: {
      selector: '#secret',
      visual_reason: 'Clear before entering a secret',
      is_final: true,
    },
  });
  assert.equal(result.isError, false);
  assert.equal(calls[0].route, 'clear');
  assert.deepEqual(calls[0].envelope.visual, {
    visual_reason: 'Clear before entering a secret',
    is_final: true,
  });
  assert.equal(Object.hasOwn(calls[0].envelope.visual, 'client'), false);
  assert.equal(Object.hasOwn(calls[0].envelope, 'session_id'), false);
});

test('unknown supplied badge is denied before native dispatch and private text is not logged', async () => {
  const calls = [];
  const diagnostics = [];
  const privateReason = 'private account reason 9f8d';
  const handler = createToolHandler({
    session: {
      command: async (...args) => calls.push(args),
    },
    diagnostic: (message) => diagnostics.push(String(message)),
  });
  const result = await handler.callTool({
    name: 'click',
    arguments: {
      selector: '#submit',
      client: 'Impersonated Operator',
      visual_reason: privateReason,
    },
  });
  assert.equal(result.isError, true);
  assert.equal(result.structuredContent.error.code, 'BADGE_NOT_ALLOWED');
  assert.equal(calls.length, 0);
  assert.doesNotMatch(JSON.stringify(result), new RegExp(privateReason, 'u'));
  assert.doesNotMatch(diagnostics.join('\n'), new RegExp(privateReason, 'u'));
  assert.doesNotMatch(diagnostics.join('\n'), /Impersonated Operator/u);
});
