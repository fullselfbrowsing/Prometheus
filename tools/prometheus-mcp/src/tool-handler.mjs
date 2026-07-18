import {
  getToolDefinition,
  listToolDefinitions,
  RUNTIME_NATIVE_ROUTES,
} from './catalog.mjs';
import { compatibilityError } from './errors.mjs';
import { normalizeToolArguments, ToolArgumentError } from './schema.mjs';

const LOCAL_DISPOSITIONS = new Set(['typed_stub', 'later_phase', 'removed']);
const PROVIDER_CONFIGURATION_DENIAL = Object.freeze({
  ok: false,
  error: Object.freeze({
    code: 'LOCAL_UI_REQUIRED',
    recovery: 'Open the Prometheus local control panel to change provider configuration.',
  }),
});
const VISUAL_FIELDS = new Set(['visual_reason', 'client', 'is_final']);
const DENIED_RESULT_FIELDS = new Set([
  'bearer',
  'instance_nonce',
  'profile_path',
  'session_id',
  'token',
  'visual_reason',
]);
const DIAGNOSTIC_KEYS = Object.freeze([
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
]);
const DIAGNOSTIC_STATUSES = new Set([
  'ready',
  'degraded',
  'not_ready',
  'unavailable',
]);
const LATER_DIAGNOSTICS = new Set([
  'supervision',
  'extensions',
]);
const RUNTIME_ROUTE_SET = new Set(RUNTIME_NATIVE_ROUTES);

const diagnosticCopy = Object.freeze({
  browser: ['Browser process status reported by Prometheus.', 'Keep the Prometheus browser running.'],
  bridge: ['External MCP bridge is connected.', 'Keep this MCP process connected.'],
  active_tab: ['Active regular-profile tab status reported by Prometheus.', 'Open or target a regular-profile tab if unavailable.'],
  content_adapter: ['Normal-page adapter status reported by Prometheus.', 'Use bounded page routes when ready.'],
  internal_adapter: ['Closed internal-surface adapter status reported by Prometheus.', 'Use a documented Prometheus surface when ready.'],
  webui_adapter: ['Prometheus WebUI adapter status reported by Prometheus.', 'Use browser-owned WebUI routes when ready.'],
  vault: ['Profile-owned native vault status reported by Prometheus.', 'Use the local control panel when vault recovery is required.'],
  provider: ['Provider runtime status reported by Prometheus.', 'Use the local control panel when provider recovery is required.'],
  supervision: ['Supervision is not ready in this phase.', 'Retry after Phase 21 supervision support is ready.'],
  extensions: ['Extension policy is not ready in this phase.', 'Retry after Phase 22 extension support is ready.'],
});

const isRecord = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

const localFailure = (code, recovery) => ({
  ok: false,
  error: { code, recovery },
});

const sanitizeResult = (value, depth = 0) => {
  if (depth > 32) throw new TypeError('Native result nesting is invalid.');
  if (Array.isArray(value)) {
    return value.map((item) => sanitizeResult(item, depth + 1));
  }
  if (!isRecord(value)) return value;
  const sanitized = {};
  for (const [key, item] of Object.entries(value)) {
    if (!DENIED_RESULT_FIELDS.has(key)) {
      sanitized[key] = sanitizeResult(item, depth + 1);
    }
  }
  return sanitized;
};

export const createToolResult = (structuredContent, isError) => ({
  content: [{ type: 'text', text: JSON.stringify(structuredContent) }],
  structuredContent,
  isError,
});

const resultFor = (structuredContent) => {
  const sanitized = sanitizeResult(structuredContent);
  return createToolResult(sanitized, sanitized?.ok !== true);
};

const argumentFailure = (error) => localFailure(
  error instanceof ToolArgumentError ? error.code : 'INVALID_ARGUMENT',
  'Correct the declared tool arguments and retry.',
);

const toNativeEnvelope = (normalized) => {
  const target = {};
  const params = {};
  const visual = {};
  const element = {};
  const frame = {};

  for (const [key, value] of Object.entries(normalized)) {
    if (key === 'target') {
      if (value.tab_id !== undefined) target.tab_id = value.tab_id;
      if (value.tab_index !== undefined) target.tabIndex = value.tab_index;
    } else if (VISUAL_FIELDS.has(key)) {
      visual[key] = value;
    } else if (key === 'ref') {
      element.element_ref = value;
    } else if (key === 'selector') {
      element.selector = value;
    } else if (key === 'document_token') {
      frame.document_token = value;
    } else if (key === 'attribute') {
      params.attribute_name = value;
    } else if (key === 'delta_x') {
      params.scroll_delta_x = value;
    } else if (key === 'delta_y') {
      params.scroll_delta_y = value;
    } else {
      params[key] = value;
    }
  }
  if (Object.keys(element).length > 0) params.element = element;
  if (Object.keys(frame).length > 0) params.frame = frame;
  return { target, params, visual };
};

const safeDiagnostics = (nativeResult) => {
  if (nativeResult?.ok === false) {
    return nativeResult;
  }
  if (nativeResult?.ok !== true || !Array.isArray(nativeResult.diagnostics)
      || nativeResult.diagnostics.length !== DIAGNOSTIC_KEYS.length) {
    return localFailure(
      'DIAGNOSTICS_INVALID',
      'Restart Prometheus and retry diagnostics.',
    );
  }
  const byKey = new Map();
  for (const component of nativeResult.diagnostics) {
    if (!isRecord(component) || !DIAGNOSTIC_KEYS.includes(component.key)
        || !DIAGNOSTIC_STATUSES.has(component.status)
        || byKey.has(component.key)) {
      return localFailure(
        'DIAGNOSTICS_INVALID',
        'Restart Prometheus and retry diagnostics.',
      );
    }
    byKey.set(component.key, component.status);
  }
  if (byKey.size !== DIAGNOSTIC_KEYS.length) {
    return localFailure(
      'DIAGNOSTICS_INVALID',
      'Restart Prometheus and retry diagnostics.',
    );
  }
  return {
    ok: true,
    components: DIAGNOSTIC_KEYS.map((key) => {
      const [reason, nextAction] = diagnosticCopy[key];
      return {
        key,
        status: key === 'bridge'
          ? 'ready'
          : LATER_DIAGNOSTICS.has(key) ? 'not_ready' : byKey.get(key),
        reason,
        next_action: nextAction,
      };
    }),
  };
};

export const createToolHandler = ({
  session,
  diagnostic = () => {},
  normalizeArguments = normalizeToolArguments,
}) => {
  if (!session) throw new TypeError('A browser session is required.');
  if (typeof normalizeArguments !== 'function') {
    throw new TypeError('A tool argument normalizer is required.');
  }

  const listTools = () => listToolDefinitions().map((definition) => ({
    name: definition.name,
    description: definition.description,
    inputSchema: definition.inputSchema,
  }));

  const callTool = async (call, { signal } = {}) => {
    if (!isRecord(call) || typeof call.name !== 'string') {
      return resultFor(localFailure(
        'INVALID_ARGUMENT',
        'Call a tool by its advertised name.',
      ));
    }
    const definition = getToolDefinition(call.name);
    if (!definition) {
      return resultFor(localFailure(
        'UNKNOWN_TOOL',
        'Refresh tools/list and call an advertised tool.',
      ));
    }
    if (LOCAL_DISPOSITIONS.has(definition.disposition)) {
      return resultFor(compatibilityError(definition));
    }
    if (definition.nativeRoute === 'set_provider_config') {
      return resultFor(PROVIDER_CONFIGURATION_DENIAL);
    }

    let normalized;
    try {
      normalized = normalizeArguments(definition, call.arguments ?? {});
    } catch (error) {
      return resultFor(argumentFailure(error));
    }

    try {
      if (definition.name === 'diagnostics') {
        return resultFor(safeDiagnostics(await session.health({ signal })));
      }
      const withPreset = {
        ...normalized,
        ...(definition.presetArguments ?? {}),
      };
      const envelope = RUNTIME_ROUTE_SET.has(definition.nativeRoute)
        ? { params: withPreset }
        : toNativeEnvelope(withPreset);
      const nativeResult = await session.command(
        definition.nativeRoute,
        envelope,
        { signal },
      );
      return resultFor(nativeResult);
    } catch {
      diagnostic('native request unavailable');
      return resultFor(localFailure(
        'NATIVE_UNAVAILABLE',
        'Confirm Prometheus is running and retry.',
      ));
    }
  };

  return { listTools, callTool };
};
