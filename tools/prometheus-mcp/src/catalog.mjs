const MAX_TARGET_ID = 2_147_483_647;

const utf8String = (maxBytes, minBytes = 0) => ({
  type: 'string',
  minLength: minBytes,
  maxLength: maxBytes,
  xMaxUtf8Bytes: maxBytes,
  ...(minBytes > 0 ? { xMinUtf8Bytes: minBytes } : {}),
});

const positiveTarget = {
  type: 'integer',
  minimum: 1,
  maximum: MAX_TARGET_ID,
};

const targetProperties = {
  tab_id: positiveTarget,
  tabId: positiveTarget,
  tabIndex: {
    type: 'integer',
    minimum: 0,
    maximum: MAX_TARGET_ID,
  },
};

const visualProperties = {
  visual_reason: utf8String(256, 1),
  client: utf8String(80, 1),
  is_final: { type: 'boolean' },
};

const objectSchema = (properties = {}, required = []) => ({
  type: 'object',
  properties,
  required,
  additionalProperties: false,
});

const targetedSchema = (properties = {}, required = [], visual = false) =>
  objectSchema(
    {
      ...targetProperties,
      ...properties,
      ...(visual ? visualProperties : {}),
    },
    required,
  );

const emptySchema = objectSchema();
const visualTargetSchema = targetedSchema({}, [], true);
const elementProperties = {
  ref: utf8String(4096, 1),
  selector: utf8String(4096, 1),
  document_token: utf8String(4096, 1),
};
const readLimitProperties = {
  max_chars: { type: 'integer', minimum: 1, maximum: 200_000 },
  max_nodes: { type: 'integer', minimum: 1, maximum: 10_000 },
  compact: { type: 'boolean' },
};

const runtimeId = utf8String(128, 1);
const providerId = utf8String(64, 1);
const listLimit = { type: 'integer', minimum: 1, maximum: 128 };
const tags = {
  type: 'array',
  items: utf8String(64, 1),
  minItems: 0,
  maxItems: 8,
};
const httpOrigin = {
  ...utf8String(2048, 1),
  xUriKind: 'http-origin',
};
const httpsOrigin = {
  ...utf8String(2048, 1),
  xUriKind: 'https-origin',
};
const providerEndpoint = {
  ...utf8String(2048, 1),
  xUriKind: 'http-url',
};
const vaultKind = {
  oneOf: [
    { type: 'string', enum: ['credential'] },
    { type: 'string', enum: ['payment'] },
  ],
};

const runtimeSchemas = {
  run_task: objectSchema(
    {
      prompt: utf8String(64 * 1024, 1),
      requested_execution: {
        type: 'string',
        enum: ['auto', 'provider', 'local'],
      },
      provider_id: providerId,
    },
    ['prompt', 'requested_execution'],
  ),
  stop_task: objectSchema({ task_id: runtimeId }, ['task_id']),
  get_task_status: objectSchema({ task_id: runtimeId }, ['task_id']),
  list_tasks: objectSchema({ limit: listLimit }),
  get_provider_config: objectSchema({ provider_id: providerId }, ['provider_id']),
  list_providers: objectSchema({ include_disabled: { type: 'boolean' } }),
  discover_models: objectSchema({ provider_id: providerId }, ['provider_id']),
  set_provider_config: objectSchema(
    {
      provider_id: providerId,
      label: utf8String(128, 1),
      kind: {
        type: 'string',
        enum: [
          'openai',
          'anthropic',
          'gemini',
          'xai',
          'openrouter',
          'lm_studio',
          'hosted',
          'routed',
          'local',
          'custom',
        ],
      },
      route_class: {
        type: 'string',
        enum: ['hosted', 'routed', 'local', 'custom'],
      },
      endpoint: providerEndpoint,
      model_id: utf8String(128, 1),
      fallback_rank: { type: 'integer', minimum: 0, maximum: 31 },
      input_rate_microunits: {
        type: 'integer',
        minimum: 0,
        maximum: 1_000_000_000,
      },
      output_rate_microunits: {
        type: 'integer',
        minimum: 0,
        maximum: 1_000_000_000,
      },
      enabled: { type: 'boolean' },
      trusted: { type: 'boolean' },
      configure_secret: { type: 'boolean' },
    },
    ['provider_id'],
  ),
  get_logs: objectSchema({ limit: listLimit }),
  action_history: objectSchema({ task_id: runtimeId, limit: listLimit }),
  runtime_diagnostics: emptySchema,
  save_memory: objectSchema(
    {
      title: utf8String(256, 1),
      text: utf8String(16 * 1024, 1),
      tags,
      shared: { type: 'boolean' },
    },
    ['title', 'text', 'tags'],
  ),
  list_memory: objectSchema({ limit: listLimit }),
  save_site_guide: objectSchema(
    {
      title: utf8String(256, 1),
      instructions: utf8String(16 * 1024, 1),
      canonical_origin: httpOrigin,
      tags,
      shared: { type: 'boolean' },
    },
    ['title', 'instructions', 'canonical_origin', 'tags'],
  ),
  list_site_guides: objectSchema({ limit: listLimit }),
  create_vault_entry: objectSchema(
    {
      label: utf8String(160, 1),
      kind: vaultKind,
      canonical_site_origin: httpsOrigin,
    },
    ['label', 'kind', 'canonical_site_origin'],
  ),
  list_vault_entries: objectSchema({ kind: vaultKind }),
  vault_autofill: objectSchema({ entry_id: runtimeId }, ['entry_id']),
  list_sessions: objectSchema({ limit: listLimit }),
  get_session_detail: objectSchema({ run_id: runtimeId }, ['run_id']),
  search_memory: objectSchema(
    { query: utf8String(256, 1), limit: listLimit },
    ['query'],
  ),
  get_memory_stats: emptySchema,
  get_site_guide: objectSchema({ guide_id: runtimeId }, ['guide_id']),
  list_credentials: objectSchema({ limit: listLimit }),
  fill_credential: objectSchema({ entry_id: runtimeId }, ['entry_id']),
  list_payment_methods: objectSchema({ limit: listLimit }),
  use_payment_method: objectSchema({ entry_id: runtimeId }, ['entry_id']),
};

const nativeSchemas = {
  list_tabs: emptySchema,
  open_tab: objectSchema({
    url: utf8String(4096, 1),
    foreground: { type: 'boolean' },
    ...visualProperties,
  }),
  navigate: targetedSchema({ url: utf8String(4096, 1) }, ['url'], true),
  reload: visualTargetSchema,
  go_back: visualTargetSchema,
  go_forward: visualTargetSchema,
  close_tab: visualTargetSchema,
  read_page: targetedSchema(readLimitProperties),
  get_text: targetedSchema(elementProperties),
  get_attribute: targetedSchema(
    { ...elementProperties, attribute: utf8String(128, 1) },
    ['attribute'],
  ),
  get_dom_snapshot: targetedSchema(readLimitProperties),
  get_page_snapshot: targetedSchema(readLimitProperties),
  execute_js: targetedSchema(
    {
      javascript: utf8String(20_000, 1),
      javascript_permission_granted: { type: 'boolean' },
      verify_mutation: { type: 'boolean' },
    },
    ['javascript'],
    true,
  ),
  click: targetedSchema(elementProperties, [], true),
  type_text: targetedSchema(
    { ...elementProperties, text: utf8String(20_000) },
    ['text'],
    true,
  ),
  press_key: targetedSchema(
    { ...elementProperties, key: utf8String(128, 1) },
    ['key'],
    true,
  ),
  scroll: targetedSchema(
    {
      ...elementProperties,
      delta_x: { type: 'integer', minimum: -2_147_483_648, maximum: MAX_TARGET_ID },
      delta_y: { type: 'integer', minimum: -2_147_483_648, maximum: MAX_TARGET_ID },
    },
    [],
    true,
  ),
  hover: targetedSchema(elementProperties, [], true),
  select_option: targetedSchema(
    { ...elementProperties, option_value: utf8String(4096) },
    ['option_value'],
    true,
  ),
  clear: targetedSchema(elementProperties, [], true),
  diagnostics: emptySchema,
  open_internal_surface: objectSchema(
    {
      surface: {
        type: 'string',
        enum: ['new_tab', 'side_panel', 'control_panel'],
      },
      ...visualProperties,
    },
    ['surface'],
  ),
  ...runtimeSchemas,
};

const aliasDefinitions = {
  new_tab: { nativeRoute: 'open_tab', inputSchema: nativeSchemas.open_tab },
  switch_tab: { nativeRoute: 'activate_tab', inputSchema: visualTargetSchema },
  refresh: { nativeRoute: 'reload', inputSchema: nativeSchemas.reload },
  back: { nativeRoute: 'go_back', inputSchema: nativeSchemas.go_back },
  type: { nativeRoute: 'type_text', inputSchema: nativeSchemas.type_text },
  press_enter: {
    nativeRoute: 'press_key',
    inputSchema: targetedSchema(elementProperties, [], true),
    presetArguments: { key: 'Enter' },
  },
  select: {
    nativeRoute: 'select_option',
    inputSchema: nativeSchemas.select_option,
  },
  clear_input: { nativeRoute: 'clear', inputSchema: nativeSchemas.clear },
  submit_task: {
    nativeRoute: 'run_task',
    inputSchema: runtimeSchemas.run_task,
  },
  cancel_task: {
    nativeRoute: 'stop_task',
    inputSchema: runtimeSchemas.stop_task,
  },
  task_status: {
    nativeRoute: 'get_task_status',
    inputSchema: runtimeSchemas.get_task_status,
  },
  list_runtime_logs: {
    nativeRoute: 'get_logs',
    inputSchema: runtimeSchemas.get_logs,
  },
};

const phase21Names = [
  'create_supervision_pairing',
  'start_supervision_session',
  'get_supervision_snapshot',
  'get_supervision_diff',
  'end_supervision_session',
];

const typedStubDefinitions = {
  check_box: ['UNSUPPORTED_ROUTE', ['click']],
  click_and_hold: ['UNSUPPORTED_ROUTE', ['click']],
  click_at: ['UNSUPPORTED_ROUTE', ['click']],
  double_click: ['UNSUPPORTED_ROUTE', ['click']],
  double_click_at: ['UNSUPPORTED_ROUTE', ['click']],
  drag: ['CAPABILITY_NOT_READY', []],
  drag_drop: ['CAPABILITY_NOT_READY', []],
  drag_variable_speed: ['CAPABILITY_NOT_READY', []],
  drop_file: ['CAPABILITY_NOT_READY', []],
  fill_sheet: ['UNSUPPORTED_ROUTE', ['type_text']],
  focus: ['UNSUPPORTED_ROUTE', ['click']],
  insert_text: ['UNSUPPORTED_ROUTE', ['type_text']],
  read_sheet: ['UNSUPPORTED_ROUTE', ['read_page']],
  right_click: ['UNSUPPORTED_ROUTE', ['click']],
  scroll_at: ['UNSUPPORTED_ROUTE', ['scroll']],
  scroll_to_bottom: ['UNSUPPORTED_ROUTE', ['scroll']],
  scroll_to_element: ['UNSUPPORTED_ROUTE', ['scroll']],
  scroll_to_top: ['UNSUPPORTED_ROUTE', ['scroll']],
  search: ['UNSUPPORTED_ROUTE', ['navigate']],
  select_text_range: ['UNSUPPORTED_ROUTE', ['get_text']],
  set_attribute: ['UNSUPPORTED_ROUTE', ['type_text', 'select_option']],
  wait_for_load: ['UNSUPPORTED_ROUTE', ['read_page']],
};

const stubSchemas = {
  click_at: objectSchema({ x: { type: 'number' }, y: { type: 'number' }, ...visualProperties }, ['x', 'y']),
  double_click_at: objectSchema({ x: { type: 'number' }, y: { type: 'number' }, ...visualProperties }, ['x', 'y']),
  scroll_at: objectSchema({
    x: { type: 'number' },
    y: { type: 'number' },
    delta_x: { type: 'number' },
    delta_y: { type: 'number' },
    ...visualProperties,
  }, ['x', 'y']),
  set_attribute: targetedSchema(
    {
      ...elementProperties,
      attribute: utf8String(128, 1),
      value: utf8String(20_000),
    },
    ['attribute', 'value'],
    true,
  ),
};

const describe = (name, disposition) =>
  `${name.replaceAll('_', ' ')} compatibility tool (${disposition}).`;

const catalog = [];

for (const [name, inputSchema] of Object.entries(nativeSchemas)) {
  catalog.push({
    name,
    description: name === 'set_provider_config'
      ? 'Provider metadata compatibility surface; use the local control UI to change configuration.'
      : describe(name, 'native'),
    inputSchema,
    disposition: 'native',
    nativeRoute: name === 'open_internal_surface' ? 'open_internal_surface' : name,
  });
}

for (const [name, definition] of Object.entries(aliasDefinitions)) {
  catalog.push({
    name,
    description: describe(name, 'alias'),
    disposition: 'alias',
    ...definition,
  });
}

for (const name of phase21Names) {
  catalog.push({
    name,
    description: describe(name, 'Phase 21'),
    inputSchema: emptySchema,
    disposition: 'later_phase',
    ownerPhase: 21,
    replacements: [],
    recovery: 'Complete Phase 21 before calling this tool.',
  });
}

for (const [name, [errorCode, replacements]] of Object.entries(typedStubDefinitions)) {
  catalog.push({
    name,
    description: describe(name, 'unavailable'),
    inputSchema: stubSchemas[name] ?? objectSchema({ ...targetProperties, ...visualProperties }),
    disposition: 'typed_stub',
    errorCode,
    replacements,
    recovery: replacements.length > 0
      ? `Use ${replacements.join(' or ')} with a stable element or tab target.`
      : 'This capability has no safe native route yet.',
  });
}

for (const name of ['start_visual_session', 'end_visual_session']) {
  catalog.push({
    name,
    description: describe(name, 'removed'),
    inputSchema: emptySchema,
    disposition: 'removed',
    errorCode: 'TOOL_REMOVED',
    replacements: ['visual_reason', 'client', 'is_final'],
    recovery: 'Supply optional visual_reason, client, or is_final metadata on an action call.',
    removed_since: '0.9.0',
    observed_as_typed_stubs_as_of: '0.9.72',
  });
}

catalog.sort((left, right) => left.name.localeCompare(right.name));

export const COMPATIBILITY_CATALOG = Object.freeze(
  catalog.map((entry) => Object.freeze(entry)),
);

const catalogByName = new Map(
  COMPATIBILITY_CATALOG.map((entry) => [entry.name, entry]),
);

export const getToolDefinition = (name) => catalogByName.get(name);

export const listToolDefinitions = () => COMPATIBILITY_CATALOG;
