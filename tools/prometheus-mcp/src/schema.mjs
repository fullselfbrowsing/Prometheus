const VISUAL_CLIENTS = [
  'Claude',
  'Codex',
  'ChatGPT',
  'Perplexity',
  'Windsurf',
  'Cursor',
  'Antigravity',
  'OpenCode',
  'OpenClaw',
  'OpenClaw 🦀',
  'Grok',
  'Gemini',
  'Hermes',
];

const badgeKey = (value) => value.toLowerCase().replace(/[\s_-]/gu, '');
const badgesByKey = new Map(VISUAL_CLIENTS.map((name) => [badgeKey(name), name]));
const MAX_RECURSIVE_DEPTH = 16;
const MAX_RECURSIVE_FIELDS = 4_096;
const SECRET_FIELDS = new Set([
  'secret',
  'apikey',
  'token',
  'password',
  'authorization',
  'ciphertext',
  'paymentvalue',
  'approvaltoken',
]);
const AUTHORITY_FIELDS = new Set([
  'callerid',
  'profileid',
  'profilepath',
  'ownerid',
  'principalid',
  'gatewaysessionid',
  'sessionid',
]);
const PROTOTYPE_FIELDS = new Set(['__proto__', 'prototype', 'constructor']);

export class ToolArgumentError extends Error {
  constructor(code, message, field) {
    super(message);
    this.name = 'ToolArgumentError';
    this.code = code;
    this.field = field;
  }
}

const reject = (code, message, field) => {
  throw new ToolArgumentError(code, message, field);
};

const normalizeFieldName = (field) =>
  field.replace(/[^a-z0-9]/giu, '').toLowerCase();

const isRecord = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

const scanReservedFields = (value, depth = 0, state = { visited: 0 }) => {
  state.visited += 1;
  if (depth > MAX_RECURSIVE_DEPTH || state.visited > MAX_RECURSIVE_FIELDS) {
    reject('INVALID_ARGUMENT', 'Tool arguments exceed recursive bounds.');
  }
  if (Array.isArray(value)) {
    for (const item of value) {
      scanReservedFields(item, depth + 1, state);
    }
    return;
  }
  if (!isRecord(value)) return;

  const prototype = Object.getPrototypeOf(value);
  if (prototype !== Object.prototype && prototype !== null) {
    reject(
      'SECRET_TRANSPORT_BLOCKED',
      'Prototype-shaped input cannot cross the MCP transport.',
    );
  }
  for (const field of Object.keys(value)) {
    const normalized = normalizeFieldName(field);
    if (SECRET_FIELDS.has(normalized) || PROTOTYPE_FIELDS.has(field)) {
      reject(
        'SECRET_TRANSPORT_BLOCKED',
        'Secret-shaped fields cannot cross the MCP transport.',
      );
    }
    if (AUTHORITY_FIELDS.has(normalized)) {
      reject(
        'INVALID_ARGUMENT',
        'Runtime authority is derived by the browser.',
      );
    }
    scanReservedFields(value[field], depth + 1, state);
  }
};

export const normalizeVisualClient = (client) => {
  if (client === undefined) {
    return 'External Client';
  }
  if (typeof client !== 'string') {
    reject('BADGE_NOT_ALLOWED', 'The supplied client badge is not allowed.', 'client');
  }
  const normalized = badgesByKey.get(badgeKey(client));
  if (!normalized) {
    reject('BADGE_NOT_ALLOWED', 'The supplied client badge is not allowed.', 'client');
  }
  return normalized;
};

const coerceNumber = (value, schema, field) => {
  let number = value;
  if (typeof number === 'string') {
    const trimmed = number.trim();
    if (
      trimmed.length === 0 ||
      !/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/u.test(trimmed)
    ) {
      reject('INVALID_ARGUMENT', `Numeric field ${field} is invalid.`, field);
    }
    number = Number(trimmed);
  }
  if (typeof number !== 'number' || !Number.isFinite(number)) {
    reject('INVALID_ARGUMENT', `Numeric field ${field} must be finite.`, field);
  }
  if (schema.type === 'integer' && !Number.isInteger(number)) {
    reject('INVALID_ARGUMENT', `Numeric field ${field} must be an integer.`, field);
  }
  if (schema.minimum !== undefined && number < schema.minimum) {
    reject('INVALID_ARGUMENT', `Numeric field ${field} is below its bound.`, field);
  }
  if (schema.maximum !== undefined && number > schema.maximum) {
    reject('INVALID_ARGUMENT', `Numeric field ${field} exceeds its bound.`, field);
  }
  return number;
};

const validateUri = (value, kind, field) => {
  let parsed;
  try {
    parsed = new URL(value);
  } catch {
    reject('INVALID_ARGUMENT', `Field ${field} is not a valid URL.`, field);
  }
  const http = parsed.protocol === 'http:' || parsed.protocol === 'https:';
  const https = parsed.protocol === 'https:';
  const originOnly = parsed.pathname === '/' && parsed.search === ''
    && parsed.hash === '';
  if (!http || parsed.hostname.length === 0
      || parsed.username.length > 0 || parsed.password.length > 0
      || parsed.search.length > 0 || parsed.hash.length > 0
      || (kind === 'https-origin' && (!https || !originOnly))
      || (kind === 'http-origin' && !originOnly)) {
    reject('INVALID_ARGUMENT', `Field ${field} is not an allowed URL.`, field);
  }
};

const normalizeValue = (field, value, schema, depth = 0) => {
  if (!schema || depth > MAX_RECURSIVE_DEPTH) {
    reject('INVALID_ARGUMENT', `Field ${field} has an invalid schema.`, field);
  }
  if (schema.oneOf) {
    const matches = [];
    for (const branch of schema.oneOf) {
      try {
        matches.push(normalizeValue(field, value, branch, depth + 1));
      } catch (error) {
        if (!(error instanceof ToolArgumentError)) throw error;
      }
    }
    if (matches.length !== 1) {
      reject('INVALID_ARGUMENT', `Field ${field} matches no allowed variant.`, field);
    }
    return matches[0];
  }
  if (schema.type === 'integer' || schema.type === 'number') {
    return coerceNumber(value, schema, field);
  }
  if (schema.type === 'string') {
    if (typeof value !== 'string') {
      reject('INVALID_ARGUMENT', `Field ${field} must be a string.`, field);
    }
    const byteLength = Buffer.byteLength(value, 'utf8');
    const minimum = schema.xMinUtf8Bytes ?? schema.minLength;
    const maximum = schema.xMaxUtf8Bytes ?? schema.maxLength;
    if (minimum !== undefined && byteLength < minimum) {
      reject('INVALID_ARGUMENT', `Field ${field} is below its bound.`, field);
    }
    if (maximum !== undefined && byteLength > maximum) {
      reject('INVALID_ARGUMENT', `Field ${field} exceeds its bound.`, field);
    }
    if (schema.enum && !schema.enum.includes(value)) {
      reject('INVALID_ARGUMENT', `Field ${field} is not an allowed value.`, field);
    }
    if (schema.pattern && !(new RegExp(schema.pattern, 'u')).test(value)) {
      reject('INVALID_ARGUMENT', `Field ${field} has an invalid format.`, field);
    }
    if (schema.xUriKind) validateUri(value, schema.xUriKind, field);
    return value;
  }
  if (schema.type === 'boolean') {
    if (typeof value !== 'boolean') {
      reject('INVALID_ARGUMENT', `Field ${field} must be a boolean.`, field);
    }
    return value;
  }
  if (schema.type === 'array') {
    if (!Array.isArray(value)) {
      reject('INVALID_ARGUMENT', `Field ${field} must be an array.`, field);
    }
    if (schema.minItems !== undefined && value.length < schema.minItems) {
      reject('INVALID_ARGUMENT', `Field ${field} is below its item bound.`, field);
    }
    if (schema.maxItems !== undefined && value.length > schema.maxItems) {
      reject('INVALID_ARGUMENT', `Field ${field} exceeds its item bound.`, field);
    }
    return value.map((item, index) =>
      normalizeValue(`${field}[${index}]`, item, schema.items, depth + 1));
  }
  if (schema.type === 'object') {
    if (!isRecord(value)) {
      reject('INVALID_ARGUMENT', `Field ${field} must be an object.`, field);
    }
    const properties = schema.properties ?? {};
    for (const name of Object.keys(value)) {
      if (!Object.hasOwn(properties, name)) {
        reject('INVALID_ARGUMENT', `Undeclared field ${name} is not allowed.`, name);
      }
    }
    for (const name of schema.required ?? []) {
      if (!Object.hasOwn(value, name)) {
        reject('INVALID_ARGUMENT', `Required field ${name} is missing.`, name);
      }
    }
    const normalized = {};
    for (const [name, item] of Object.entries(value)) {
      normalized[name] = normalizeValue(
        `${field}.${name}`,
        item,
        properties[name],
        depth + 1,
      );
    }
    return normalized;
  }
  reject('INVALID_ARGUMENT', `Field ${field} has an unsupported schema.`, field);
};

const normalizeTarget = (normalized) => {
  const supplied = ['tab_id', 'tabId', 'tabIndex'].filter(
    (field) => normalized[field] !== undefined,
  );
  if (supplied.length === 0 && normalized.extension_surface === undefined) {
    return;
  }
  if (
    normalized.tabIndex !== undefined &&
    (normalized.tab_id !== undefined || normalized.tabId !== undefined)
  ) {
    reject('INVALID_TARGET', 'Conflicting tab target fields were supplied.', 'target');
  }
  if (
    normalized.tab_id !== undefined &&
    normalized.tabId !== undefined &&
    normalized.tab_id !== normalized.tabId
  ) {
    reject('INVALID_TARGET', 'Conflicting tab target fields were supplied.', 'target');
  }
  if (
    normalized.extension_surface !== undefined &&
    (normalized.tab_id === undefined || normalized.tabId !== undefined
      || normalized.tabIndex !== undefined)
  ) {
    reject(
      'INVALID_TARGET',
      'An extension surface requires one positive stable tab_id.',
      'target',
    );
  }
  const stable = normalized.tab_id ?? normalized.tabId;
  normalized.target = stable === undefined
    ? { tab_index: normalized.tabIndex }
    : {
      tab_id: stable,
      ...(normalized.extension_surface === undefined
        ? {}
        : { extension_surface: normalized.extension_surface }),
    };
  delete normalized.tab_id;
  delete normalized.tabId;
  delete normalized.tabIndex;
  delete normalized.extension_surface;
};

export const normalizeToolArguments = (definition, raw = {}) => {
  if (!definition?.inputSchema || definition.inputSchema.type !== 'object') {
    reject('INVALID_ARGUMENT', 'Tool definition has no object schema.');
  }
  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
    reject('INVALID_ARGUMENT', 'Tool arguments must be an object.');
  }
  scanReservedFields(raw);
  const normalized = normalizeValue('arguments', raw, definition.inputSchema);
  normalizeTarget(normalized);
  if (Object.hasOwn(normalized, 'client')) {
    normalized.client = normalizeVisualClient(normalized.client);
  }
  return normalized;
};

export const VISUAL_CLIENT_BADGES = Object.freeze([...VISUAL_CLIENTS]);
