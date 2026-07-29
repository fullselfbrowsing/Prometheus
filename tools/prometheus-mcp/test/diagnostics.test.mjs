import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import { getToolDefinition } from '../src/catalog.mjs';
import { createToolHandler } from '../src/tool-handler.mjs';

const fixture = JSON.parse(
  await readFile(new URL('fixtures/protocol-cases.json', import.meta.url), 'utf8'),
);

const expectedKeys = [
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
];
const statuses = new Set(['ready', 'degraded', 'not_ready', 'unavailable']);
const deniedFields = new Set([
  'token',
  'bearer',
  'profile_path',
  'page_text',
  'script',
  'visual_reason',
]);

const extensionReasonByStatus = Object.freeze({
  ready: 'extension_policy_ready',
  degraded: 'extension_system_not_ready',
  unavailable: 'extension_policy_unavailable',
});

const nativeHealth = ({
  extensionStatus = 'ready',
  extensionReason = extensionReasonByStatus[extensionStatus],
  extensionRecovery = 'No extension recovery action is required.',
} = {}) => ({
  ok: true,
  diagnostics: expectedKeys.map((key) => ({
    key,
    status: key === 'extensions' ? extensionStatus : 'ready',
    reason: key === 'extensions'
      ? extensionReason
      : 'Private native reason must not be forwarded.',
    next_action: key === 'extensions'
      ? extensionRecovery
      : 'Private native recovery must not be forwarded.',
  })),
});

const containsSentinelRecursively = (value, sentinel) => {
  if (typeof value === 'string') return value.includes(sentinel);
  if (Array.isArray(value)) {
    return value.some((child) => containsSentinelRecursively(child, sentinel));
  }
  if (!value || typeof value !== 'object') return false;
  return Object.entries(value).some(
    ([key, child]) => key.includes(sentinel)
      || containsSentinelRecursively(child, sentinel),
  );
};

test('Wave 0 diagnostics fixture has exactly ten closed components', () => {
  const components = fixture.diagnostics.components;
  assert.deepEqual(components.map(({ key }) => key), expectedKeys);
  assert.equal(new Set(components.map(({ key }) => key)).size, 10);
  for (const component of components) {
    assert.ok(statuses.has(component.status), component.key);
    for (const field of Object.keys(component)) {
      assert.equal(deniedFields.has(field), false, field);
    }
  }
  assert.equal(getToolDefinition('diagnostics').disposition, 'native');
});

test('diagnostic serialization contains no secret or page-content field names', () => {
  const serialized = JSON.stringify(fixture.diagnostics);
  for (const field of deniedFields) {
    assert.equal(serialized.includes(`\"${field}\"`), false, field);
  }
});

test('Phase 22 extension diagnostics preserve live bounded status and recovery', async () => {
  for (const extensionStatus of ['ready', 'degraded', 'unavailable']) {
    const extensionReason = extensionReasonByStatus[extensionStatus];
    const extensionRecovery = extensionStatus === 'ready'
      ? 'No extension recovery action is required.'
      : 'Open Extension policy and try again.';
    let healthCalls = 0;
    let commandCalls = 0;
    const handler = createToolHandler({
      session: {
        health: async () => {
          healthCalls += 1;
          return nativeHealth({
            extensionStatus,
            extensionReason,
            extensionRecovery,
          });
        },
        command: async () => { commandCalls += 1; },
      },
    });
    const result = await handler.callTool({
      name: 'diagnostics',
      arguments: {},
    });
    assert.equal(result.isError, false, extensionStatus);
    assert.equal(healthCalls, 1);
    assert.equal(commandCalls, 0);
    const { components } = result.structuredContent;
    assert.deepEqual(components.map(({ key }) => key), expectedKeys);
    assert.equal(new Set(components.map(({ key }) => key)).size, 10);
    const extensions = components.at(-1);
    assert.deepEqual(extensions, {
      key: 'extensions',
      status: extensionStatus,
      reason: extensionReason,
      next_action: extensionRecovery,
    });
    assert.ok(Buffer.byteLength(extensions.reason, 'utf8') <= 48);
    assert.ok(Buffer.byteLength(extensions.next_action, 'utf8') <= 160);
    for (const component of components) {
      assert.ok(statuses.has(component.status), component.key);
    }
    const privateSentinels = [
      'abcdefghijklmnopabcdefghijklmnop',
      'Installed extension inventory sentinel',
      'manifest_permissions',
      'https://private-origin.example',
      'page-content-sentinel',
      'form-value-sentinel',
      'script-source-sentinel',
      '/Users/private/profile',
      'browser-session-sentinel',
      'bearer-authority-sentinel',
      'Interact',
    ];
    for (const sentinel of privateSentinels) {
      assert.equal(containsSentinelRecursively(result, sentinel), false);
    }
  }
});

test('Phase 22 extension diagnostics reject malformed state and recursive inventory', async () => {
  const exactLimit = nativeHealth({
    extensionRecovery: 'r'.repeat(160),
  });
  let handler = createToolHandler({
    session: { health: async () => exactLimit },
  });
  let result = await handler.callTool({ name: 'diagnostics', arguments: {} });
  assert.equal(result.isError, false);
  assert.equal(
    result.structuredContent.components.at(-1).next_action,
    'r'.repeat(160),
  );

  const reordered = nativeHealth();
  [reordered.diagnostics[0], reordered.diagnostics[1]] = [
    reordered.diagnostics[1],
    reordered.diagnostics[0],
  ];
  const missingReason = nativeHealth();
  delete missingReason.diagnostics.at(-1).reason;
  const nestedInventory = nativeHealth();
  nestedInventory.diagnostics.at(-1).details = {
    installed_extensions: [{
      extension_id: 'abcdefghijklmnopabcdefghijklmnop',
      name: 'Installed extension inventory sentinel',
      permissions: ['https://private-origin.example'],
      page_content: 'page-content-sentinel',
      profile_path: '/Users/private/profile',
      bearer: 'bearer-authority-sentinel',
    }],
  };
  const malformedHealth = [
    reordered,
    nativeHealth({ extensionStatus: 'not_ready' }),
    nativeHealth({
      extensionStatus: 'ready',
      extensionReason: 'extension_system_not_ready',
    }),
    missingReason,
    nativeHealth({ extensionReason: 'r'.repeat(49) }),
    nativeHealth({ extensionRecovery: 'r'.repeat(161) }),
    nativeHealth({ extensionRecovery: 'Bearer bearer-authority-sentinel' }),
    nestedInventory,
  ];
  for (const health of malformedHealth) {
    handler = createToolHandler({
      session: { health: async () => health },
    });
    result = await handler.callTool({ name: 'diagnostics', arguments: {} });
    assert.equal(result.isError, true);
    assert.equal(result.structuredContent.error.code, 'DIAGNOSTICS_INVALID');
    for (const sentinel of [
      'abcdefghijklmnopabcdefghijklmnop',
      'Installed extension inventory sentinel',
      'https://private-origin.example',
      'page-content-sentinel',
      '/Users/private/profile',
      'bearer-authority-sentinel',
    ]) {
      assert.equal(containsSentinelRecursively(result, sentinel), false);
    }
  }
});

test('malformed or incomplete browser health is a typed diagnostics failure', async () => {
  for (const health of [
    { ok: true, diagnostics: [] },
    { ok: true, diagnostics: expectedKeys.map((key) => ({ key, status: 'unknown' })) },
    { ok: true, diagnostics: expectedKeys.map(() => ({ key: 'browser', status: 'ready' })) },
  ]) {
    const handler = createToolHandler({
      session: { health: async () => health },
    });
    const result = await handler.callTool({ name: 'diagnostics', arguments: {} });
    assert.equal(result.isError, true);
    assert.equal(result.structuredContent.error.code, 'DIAGNOSTICS_INVALID');
  }
});
