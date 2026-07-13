import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import {
  COMPATIBILITY_CATALOG,
  getToolDefinition,
  listToolDefinitions,
} from '../src/catalog.mjs';
import { normalizeToolArguments } from '../src/schema.mjs';

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

test('every tool has a closed schema and exactly one compatibility target', () => {
  for (const entry of COMPATIBILITY_CATALOG) {
    assert.equal(entry.inputSchema.type, 'object', entry.name);
    assert.equal(entry.inputSchema.additionalProperties, false, entry.name);
    assert.ok(entry.description.length > 0, entry.name);
    const targetFields = [
      Object.hasOwn(entry, 'nativeRoute'),
      Object.hasOwn(entry, 'ownerPhase'),
      Object.hasOwn(entry, 'errorCode'),
    ].filter(Boolean);
    assert.equal(targetFields.length, 1, `${entry.name} has one target`);
  }
});

test('aliases point only to the closed native route set', () => {
  const aliases = Object.fromEntries(
    COMPATIBILITY_CATALOG
      .filter(({ disposition }) => disposition === 'alias')
      .map(({ name, nativeRoute }) => [name, nativeRoute]),
  );
  assert.deepEqual(aliases, {
    back: 'go_back',
    clear_input: 'clear',
    new_tab: 'open_tab',
    press_enter: 'press_key',
    refresh: 'reload',
    select: 'select_option',
    switch_tab: 'activate_tab',
    type: 'type_text',
  });
  const internalRoutes = new Set([
    ...COMPATIBILITY_CATALOG
      .filter(({ disposition }) => disposition === 'native')
      .map(({ nativeRoute }) => nativeRoute),
    'activate_tab',
  ]);
  for (const route of Object.values(aliases)) {
    assert.ok(internalRoutes.has(route), route);
  }
  assert.equal(getToolDefinition('activate_tab'), undefined);
  assert.deepEqual(getToolDefinition('press_enter').presetArguments, { key: 'Enter' });
});

test('native schemas enforce surface, field, and numeric boundaries', () => {
  const surface = getToolDefinition('open_internal_surface');
  for (const value of ['new_tab', 'side_panel', 'control_panel']) {
    assert.deepEqual(normalizeToolArguments(surface, { surface: value }), { surface: value });
  }
  for (const value of ['chrome://settings', 'arbitrary_route']) {
    assert.throws(
      () => normalizeToolArguments(surface, { surface: value }),
      ({ code }) => code === 'INVALID_ARGUMENT',
    );
  }
  assert.throws(
    () => normalizeToolArguments(surface, { surface: 'new_tab', route: 'navigate' }),
    ({ code }) => code === 'INVALID_ARGUMENT',
  );

  const read = getToolDefinition('read_page');
  assert.deepEqual(
    normalizeToolArguments(read, { tab_id: '7', max_chars: '200000', max_nodes: '1' }),
    { target: { tab_id: 7 }, max_chars: 200000, max_nodes: 1 },
  );
  assert.deepEqual(
    normalizeToolArguments(read, { tab_id: '42.0', max_chars: '1e2' }),
    { target: { tab_id: 42 }, max_chars: 100 },
  );
  for (const invalid of ['', ' ', 'NaN', 'Infinity', '1.5', '-1', '2147483648']) {
    assert.throws(
      () => normalizeToolArguments(read, { tab_id: invalid }),
      ({ code }) => code === 'INVALID_ARGUMENT',
      invalid,
    );
  }
  assert.throws(
    () => normalizeToolArguments(read, { tab_id: 2, tabId: 3 }),
    ({ code }) => code === 'INVALID_TARGET',
  );
  assert.deepEqual(
    normalizeToolArguments(read, { tab_id: '2', tabId: 2 }),
    { target: { tab_id: 2 } },
  );
  assert.deepEqual(normalizeToolArguments(read, { tabIndex: '0' }), {
    target: { tab_index: 0 },
  });
  assert.throws(
    () => normalizeToolArguments(read, { tabIndex: -1 }),
    ({ code }) => code === 'INVALID_ARGUMENT',
  );
  assert.throws(
    () => normalizeToolArguments(read, { tab_id: 2, tabIndex: 2 }),
    ({ code }) => code === 'INVALID_TARGET',
  );
});

test('later, removed, coordinate, mutation, and unsafe tools never claim native success', () => {
  const later20 = COMPATIBILITY_CATALOG.filter(({ ownerPhase }) => ownerPhase === 20);
  const later21 = COMPATIBILITY_CATALOG.filter(({ ownerPhase }) => ownerPhase === 21);
  assert.equal(later20.length, 31);
  assert.equal(later21.length, 5);
  for (const entry of [...later20, ...later21]) {
    assert.equal(entry.disposition, 'later_phase');
    assert.ok(entry.recovery.length > 0);
  }
  for (const name of ['start_visual_session', 'end_visual_session']) {
    const entry = getToolDefinition(name);
    assert.equal(entry.disposition, 'removed');
    assert.equal(entry.errorCode, 'TOOL_REMOVED');
    assert.equal(entry.removed_since, '0.9.0');
    assert.equal(entry.observed_as_typed_stubs_as_of, '0.9.72');
  }
  for (const name of [
    'click_at',
    'double_click_at',
    'drag',
    'drag_drop',
    'fill_sheet',
    'read_sheet',
    'set_attribute',
    'wait_for_load',
  ]) {
    assert.equal(getToolDefinition(name).disposition, 'typed_stub', name);
  }
});
