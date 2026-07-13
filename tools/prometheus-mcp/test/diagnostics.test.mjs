import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import { getToolDefinition } from '../src/catalog.mjs';

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

test.todo('Plan 19-05: return authenticated browser health components');
test.todo('Plan 19-06: merge bridge readiness without exposing credentials');
