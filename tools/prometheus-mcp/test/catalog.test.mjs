import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import {
  COMPATIBILITY_CATALOG,
  getToolDefinition,
  listToolDefinitions,
} from '../src/catalog.mjs';

const loadFixture = async (name) =>
  JSON.parse(
    await readFile(new URL(`fixtures/${name}`, import.meta.url), 'utf8'),
  );

const frozen = await loadFixture('frozen-v1-tools.json');
const current = await loadFixture('current-fsb-tools.json');

test('frozen catalogs have the expected 46/59/15/90 shape', () => {
  assert.equal(frozen.observed_count, 46);
  assert.equal(current.observed_count, 59);
  assert.equal(new Set(frozen.names).size, 46);
  assert.equal(new Set(current.names).size, 59);

  const currentNames = new Set(current.names);
  const overlap = frozen.names.filter((name) => currentNames.has(name));
  const union = new Set([...frozen.names, ...current.names]);
  assert.equal(overlap.length, 15);
  assert.equal(union.size, 90);
});

test('the compatibility catalog maps the fixture union exactly once', () => {
  const union = new Set([...frozen.names, ...current.names]);
  assert.equal(COMPATIBILITY_CATALOG.length, 90);
  assert.equal(new Set(COMPATIBILITY_CATALOG.map(({ name }) => name)).size, 90);
  assert.deepEqual(
    [...COMPATIBILITY_CATALOG.map(({ name }) => name)].sort(),
    [...union].sort(),
  );

  const dispositions = new Set([
    'native',
    'alias',
    'typed_stub',
    'later_phase',
    'removed',
  ]);
  for (const name of union) {
    const entry = getToolDefinition(name);
    assert.ok(entry, `${name} is mapped`);
    assert.ok(dispositions.has(entry.disposition), `${name} has a disposition`);
  }
  assert.deepEqual(listToolDefinitions(), COMPATIBILITY_CATALOG);
});
