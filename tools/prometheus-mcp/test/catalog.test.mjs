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

// Deliberately literal: this is the complete Phase 20 compatibility surface.
// Canonical names must remain one-to-one with the native runtime codec; only
// the four named compatibility aliases may resolve to another route.
const phase20RuntimeCases = [
  ['run_task', 'run_task', { prompt: 'Read the page', requested_execution: 'auto' }],
  ['stop_task', 'stop_task', { task_id: 'task-1' }],
  ['get_task_status', 'get_task_status', { task_id: 'task-1' }],
  ['list_tasks', 'list_tasks', { limit: 20 }],
  ['get_provider_config', 'get_provider_config', { provider_id: 'provider-1' }],
  ['list_providers', 'list_providers', { include_disabled: true }],
  ['discover_models', 'discover_models', { provider_id: 'provider-1' }],
  ['set_provider_config', 'set_provider_config', {
    provider_id: 'provider-1',
    model_id: 'safe-model',
  }],
  ['get_logs', 'get_logs', { limit: 20 }],
  ['action_history', 'action_history', { task_id: 'task-1', limit: 20 }],
  ['runtime_diagnostics', 'runtime_diagnostics', {}],
  ['save_memory', 'save_memory', {
    title: 'Title',
    text: 'Safe note',
    tags: ['one', 'two'],
    shared: false,
  }],
  ['list_memory', 'list_memory', { limit: 20 }],
  ['save_site_guide', 'save_site_guide', {
    title: 'Guide',
    instructions: 'Use the menu',
    canonical_origin: 'https://example.test',
    tags: ['one'],
    shared: true,
  }],
  ['list_site_guides', 'list_site_guides', { limit: 20 }],
  ['create_vault_entry', 'create_vault_entry', {
    label: 'Work login',
    kind: 'credential',
    canonical_site_origin: 'https://example.test',
  }],
  ['list_vault_entries', 'list_vault_entries', { kind: 'credential' }],
  ['vault_autofill', 'vault_autofill', { entry_id: 'vault-1' }],
  ['list_sessions', 'list_sessions', { limit: 20 }],
  ['get_session_detail', 'get_session_detail', { run_id: 'task-1' }],
  ['search_memory', 'search_memory', { query: 'menu', limit: 20 }],
  ['get_memory_stats', 'get_memory_stats', {}],
  ['get_site_guide', 'get_site_guide', { guide_id: 'guide-1' }],
  ['list_credentials', 'list_credentials', { limit: 20 }],
  ['fill_credential', 'fill_credential', { entry_id: 'vault-1' }],
  ['list_payment_methods', 'list_payment_methods', { limit: 20 }],
  ['use_payment_method', 'use_payment_method', { entry_id: 'vault-2' }],
];

const phase20Aliases = [
  ['submit_task', 'run_task'],
  ['cancel_task', 'stop_task'],
  ['task_status', 'get_task_status'],
  ['list_runtime_logs', 'get_logs'],
];

const phase20CompatibilityNames = [
  ...phase20RuntimeCases.map(([name]) => name),
  ...phase20Aliases.map(([name]) => name),
];

const assertSchemaIsRecursivelyClosed = (schema, path) => {
  if (schema.oneOf) {
    assert.ok(schema.oneOf.length > 0, `${path}.oneOf`);
    schema.oneOf.forEach((branch, index) =>
      assertSchemaIsRecursivelyClosed(branch, `${path}.oneOf[${index}]`));
  }
  if (schema.type === 'object') {
    assert.equal(schema.additionalProperties, false, path);
    for (const [name, property] of Object.entries(schema.properties ?? {})) {
      assertSchemaIsRecursivelyClosed(property, `${path}.${name}`);
    }
  }
  if (schema.type === 'array') {
    assert.ok(schema.items, `${path}.items`);
    assert.equal(Number.isInteger(schema.maxItems), true, `${path}.maxItems`);
    assertSchemaIsRecursivelyClosed(schema.items, `${path}[]`);
  }
};

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

test('all twelve aliases point only to the closed native route set', () => {
  const aliases = Object.fromEntries(
    COMPATIBILITY_CATALOG
      .filter(({ disposition }) => disposition === 'alias')
      .map(({ name, nativeRoute }) => [name, nativeRoute]),
  );
  assert.deepEqual(aliases, {
    back: 'go_back',
    cancel_task: 'stop_task',
    clear_input: 'clear',
    list_runtime_logs: 'get_logs',
    new_tab: 'open_tab',
    press_enter: 'press_key',
    refresh: 'reload',
    select: 'select_option',
    submit_task: 'run_task',
    switch_tab: 'activate_tab',
    task_status: 'get_task_status',
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

test('Phase 20 promotes exactly 27 native routes plus four exact aliases', () => {
  assert.equal(phase20RuntimeCases.length, 27);
  assert.equal(phase20Aliases.length, 4);
  assert.equal(new Set(phase20CompatibilityNames).size, 31);

  for (const [name, nativeRoute] of phase20RuntimeCases) {
    const definition = getToolDefinition(name);
    assert.equal(definition.disposition, 'native', name);
    assert.equal(definition.nativeRoute, nativeRoute, name);
  }
  for (const [name, nativeRoute] of phase20Aliases) {
    const definition = getToolDefinition(name);
    assert.equal(definition.disposition, 'alias', name);
    assert.equal(definition.nativeRoute, nativeRoute, name);
  }

  const counts = Object.fromEntries(
    ['native', 'alias', 'typed_stub', 'later_phase', 'removed']
      .map((disposition) => [
        disposition,
        COMPATIBILITY_CATALOG.filter((entry) => entry.disposition === disposition).length,
      ]),
  );
  assert.deepEqual(counts, {
    native: 49,
    alias: 12,
    typed_stub: 22,
    later_phase: 5,
    removed: 2,
  });
});

test('all canonical runtime schemas accept exact fixtures and close recursively', () => {
  for (const [name, nativeRoute, valid] of phase20RuntimeCases) {
    const definition = getToolDefinition(name);
    assert.equal(definition.nativeRoute, nativeRoute, name);
    assert.deepEqual(normalizeToolArguments(definition, valid), valid, name);
    assertSchemaIsRecursivelyClosed(definition.inputSchema, name);

    for (const invalid of [
      { ...valid, undeclared_field: true },
      { ...valid, caller_id: 'caller-authority-must-stay-server-side' },
    ]) {
      assert.throws(
        () => normalizeToolArguments(definition, invalid),
        ({ code }) => code === 'INVALID_ARGUMENT',
        name,
      );
    }

    const sentinel = `phase20-secret-sentinel-${name}`;
    assert.throws(
      () => normalizeToolArguments(definition, {
        ...valid,
        unknown_container: { nested: [{ api_key: sentinel }] },
      }),
      ({ code, message }) =>
        code === 'SECRET_TRANSPORT_BLOCKED' && !message.includes(sentinel),
      name,
    );
  }
});

test('runtime schemas reject route-specific invalid values and prototype keys', () => {
  const invalidCases = [
    ['run_task', { prompt: '', requested_execution: 'auto' }],
    ['run_task', { prompt: 'Read', requested_execution: 'remote' }],
    ['stop_task', { task_id: '' }],
    ['list_tasks', { limit: 0 }],
    ['list_tasks', { limit: 129 }],
    ['list_providers', { include_disabled: 'true' }],
    ['discover_models', { provider_id: '' }],
    ['set_provider_config', { provider_id: 'provider-1', fallback_rank: 32 }],
    ['save_memory', { title: 'Title', text: 'Text', tags: Array(9).fill('tag') }],
    ['save_memory', { title: 'Title', text: 'Text', tags: [7] }],
    ['save_site_guide', {
      title: 'Guide',
      instructions: 'Use the menu',
      canonical_origin: 'file:///tmp/not-allowed',
    }],
    ['create_vault_entry', {
      label: 'Work login',
      kind: 'unknown',
      canonical_site_origin: 'https://example.test',
    }],
    ['list_vault_entries', { kind: 'secret' }],
    ['search_memory', { query: '', limit: 20 }],
  ];
  for (const [name, invalid] of invalidCases) {
    assert.throws(
      () => normalizeToolArguments(getToolDefinition(name), invalid),
      ({ code }) => code === 'INVALID_ARGUMENT',
      name,
    );
  }

  const prototypeInput = JSON.parse(
    '{"prompt":"Read","requested_execution":"auto","__proto__":{"token":"blocked"}}',
  );
  assert.throws(
    () => normalizeToolArguments(getToolDefinition('run_task'), prototypeInput),
    ({ code }) => code === 'SECRET_TRANSPORT_BLOCKED',
  );
});

test('provider mutation stays native metadata-only and documents local UI recovery', () => {
  const definition = getToolDefinition('set_provider_config');
  assert.equal(definition.disposition, 'native');
  assert.equal(definition.nativeRoute, 'set_provider_config');
  assert.match(definition.description, /local (?:control )?ui/iu);
  const serialized = JSON.stringify(definition.inputSchema);
  for (const forbidden of [
    'secret',
    'api_key',
    'apiKey',
    'token',
    'password',
    'authorization',
    'approval_token',
    'provider_body',
  ]) {
    assert.equal(serialized.includes(`\"${forbidden}\"`), false, forbidden);
  }
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
  const later21 = COMPATIBILITY_CATALOG.filter(({ ownerPhase }) => ownerPhase === 21);
  assert.equal(later21.length, 5);
  assert.equal(COMPATIBILITY_CATALOG.filter(({ ownerPhase }) => ownerPhase === 20).length, 0);
  for (const entry of later21) {
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
