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

test('Phase 21 supervision diagnostics preserves live readiness while extensions stay not_ready', async () => {
  const privateText = 'private reason, profile, page, and token material';
  let healthCalls = 0;
  let commandCalls = 0;
  const handler = createToolHandler({
    session: {
      health: async () => {
        healthCalls += 1;
        return {
          ok: true,
          bearer: 'never-return-this-bearer',
          profile_path: '/private/profile/path',
          diagnostics: expectedKeys.map((key, index) => ({
            key,
            status: index < 9 ? 'ready' : 'not_ready',
            reason: privateText,
            next_action: privateText,
            page_text: privateText,
          })),
        };
      },
      command: async () => { commandCalls += 1; },
    },
  });
  const result = await handler.callTool({ name: 'diagnostics', arguments: {} });
  assert.equal(result.isError, false);
  assert.equal(healthCalls, 1);
  assert.equal(commandCalls, 0);
  const { components } = result.structuredContent;
  assert.deepEqual(components.map(({ key }) => key), expectedKeys);
  assert.equal(components.find(({ key }) => key === 'bridge').status, 'ready');
  for (const key of ['vault', 'provider', 'supervision']) {
    assert.equal(components.find((component) => component.key === key).status, 'ready');
    assert.doesNotMatch(
      components.find((component) => component.key === key).reason,
      /not ready in this phase/iu,
    );
  }
  assert.equal(
    components.find((component) => component.key === 'extensions').status,
    'not_ready',
  );
  for (const component of components) {
    assert.ok(statuses.has(component.status));
    assert.ok(component.reason.length > 0);
    assert.ok(component.next_action.length > 0);
  }
  const serialized = JSON.stringify(result);
  assert.doesNotMatch(serialized, new RegExp(privateText, 'u'));
  assert.doesNotMatch(serialized, /never-return|private\/profile|bearer|profile_path|page_text/iu);
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
