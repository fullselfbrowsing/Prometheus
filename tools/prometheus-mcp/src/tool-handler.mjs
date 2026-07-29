import { Buffer } from 'node:buffer';

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
const DENIED_SUPERVISION_RESULT_FIELDS = new Set([
  'authority',
  'bearer',
  'code',
  'content',
  'controller',
  'controller_id',
  'controller_lease',
  'cursor',
  'dashboard_session',
  'document',
  'document_epoch',
  'document_token',
  'epoch',
  'lease',
  'owner_id',
  'pairing_code',
  'profile',
  'profile_path',
  'raw_content',
  'sequence',
  'session',
  'session_id',
  'tab',
  'tab_id',
  'target',
  'token',
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
const LIVE_EXTENSION_STATUSES = new Set([
  'ready',
  'degraded',
  'unavailable',
]);
const EXTENSION_REASON_BY_STATUS = Object.freeze({
  ready: 'extension_policy_ready',
  degraded: 'extension_system_not_ready',
  unavailable: 'extension_policy_unavailable',
});
const DIAGNOSTIC_COMPONENT_FIELDS = new Set([
  'key',
  'status',
  'reason',
  'next_action',
]);
const MAX_EXTENSION_REASON_BYTES = 48;
const MAX_EXTENSION_RECOVERY_BYTES = 160;
const DENIED_EXTENSION_DIAGNOSTIC_TEXT =
  /authorization|bearer|api[_ -]?key|secret|token|session|extension[_ -]?id|permission|origin|page[_ -]?content|form[_ -]?value|script|profile[_ -]?path|\/Users\//iu;
const RUNTIME_ROUTE_SET = new Set(RUNTIME_NATIVE_ROUTES);
const SUPERVISION_NATIVE_ROUTES = new Set([
  'create_supervision_pairing',
  'start_supervision_session',
  'get_supervision_snapshot',
  'get_supervision_diff',
  'end_supervision_session',
]);

const diagnosticCopy = Object.freeze({
  browser: ['Browser process status reported by Prometheus.', 'Keep the Prometheus browser running.'],
  bridge: ['External MCP bridge is connected.', 'Keep this MCP process connected.'],
  active_tab: ['Active regular-profile tab status reported by Prometheus.', 'Open or target a regular-profile tab if unavailable.'],
  content_adapter: ['Normal-page adapter status reported by Prometheus.', 'Use bounded page routes when ready.'],
  internal_adapter: ['Closed internal-surface adapter status reported by Prometheus.', 'Use a documented Prometheus surface when ready.'],
  webui_adapter: ['Prometheus WebUI adapter status reported by Prometheus.', 'Use browser-owned WebUI routes when ready.'],
  vault: ['Profile-owned native vault status reported by Prometheus.', 'Use the local control panel when vault recovery is required.'],
  provider: ['Provider runtime status reported by Prometheus.', 'Use the local control panel when provider recovery is required.'],
  supervision: ['Native supervision status reported by Prometheus.', 'Use the local control panel if supervision recovery is required.'],
});

const isRecord = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

const isBoundedExtensionDiagnosticText = (value, maxBytes) =>
  typeof value === 'string'
  && value.length > 0
  && value === value.trim()
  && Buffer.byteLength(value, 'utf8') <= maxBytes
  && !/[\u0000-\u001f\u007f]/u.test(value)
  && !DENIED_EXTENSION_DIAGNOSTIC_TEXT.test(value);

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

const sanitizeSupervisionResult = (value, depth = 0) => {
  if (depth > 32) throw new TypeError('Native supervision result nesting is invalid.');
  if (Array.isArray(value)) {
    return value.map((item) => sanitizeSupervisionResult(item, depth + 1));
  }
  if (!isRecord(value)) return value;
  const sanitized = {};
  for (const [key, item] of Object.entries(value)) {
    if (!DENIED_SUPERVISION_RESULT_FIELDS.has(key)) {
      sanitized[key] = sanitizeSupervisionResult(item, depth + 1);
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

const supervisionResultFor = (structuredContent) => {
  const sanitized = sanitizeSupervisionResult(structuredContent);
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
      if (value.extension_surface !== undefined) {
        target.extension_surface = value.extension_surface;
      }
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
  for (const [index, component] of nativeResult.diagnostics.entries()) {
    if (!isRecord(component) || !DIAGNOSTIC_KEYS.includes(component.key)
        || !DIAGNOSTIC_STATUSES.has(component.status)
        || component.key !== DIAGNOSTIC_KEYS[index]
        || byKey.has(component.key)
        || Object.keys(component).some(
          (field) => !DIAGNOSTIC_COMPONENT_FIELDS.has(field),
        )) {
      return localFailure(
        'DIAGNOSTICS_INVALID',
        'Restart Prometheus and retry diagnostics.',
      );
    }
    if (component.key === 'extensions'
        && (!LIVE_EXTENSION_STATUSES.has(component.status)
          || component.reason !== EXTENSION_REASON_BY_STATUS[component.status]
          || !isBoundedExtensionDiagnosticText(
            component.reason,
            MAX_EXTENSION_REASON_BYTES,
          )
          || !isBoundedExtensionDiagnosticText(
            component.next_action,
            MAX_EXTENSION_RECOVERY_BYTES,
          ))) {
      return localFailure(
        'DIAGNOSTICS_INVALID',
        'Restart Prometheus and retry diagnostics.',
      );
    }
    byKey.set(component.key, component);
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
      const nativeComponent = byKey.get(key);
      if (key === 'extensions') {
        return {
          key,
          status: nativeComponent.status,
          reason: nativeComponent.reason,
          next_action: nativeComponent.next_action,
        };
      }
      const [reason, nextAction] = diagnosticCopy[key];
      return {
        key,
        status: key === 'bridge'
          ? 'ready'
          : nativeComponent.status,
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
      return SUPERVISION_NATIVE_ROUTES.has(definition.name)
        ? supervisionResultFor(nativeResult)
        : resultFor(nativeResult);
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
