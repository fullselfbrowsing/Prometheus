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

const normalizeProperty = (field, value, schema) => {
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
    return value;
  }
  if (schema.type === 'boolean') {
    if (typeof value !== 'boolean') {
      reject('INVALID_ARGUMENT', `Field ${field} must be a boolean.`, field);
    }
    return value;
  }
  reject('INVALID_ARGUMENT', `Field ${field} has an unsupported schema.`, field);
};

const normalizeTarget = (normalized) => {
  const supplied = ['tab_id', 'tabId', 'tabIndex'].filter(
    (field) => normalized[field] !== undefined,
  );
  if (supplied.length === 0) {
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
  const stable = normalized.tab_id ?? normalized.tabId;
  normalized.target = stable === undefined
    ? { tab_index: normalized.tabIndex }
    : { tab_id: stable };
  delete normalized.tab_id;
  delete normalized.tabId;
  delete normalized.tabIndex;
};

export const normalizeToolArguments = (definition, raw = {}) => {
  if (!definition?.inputSchema || definition.inputSchema.type !== 'object') {
    reject('INVALID_ARGUMENT', 'Tool definition has no object schema.');
  }
  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
    reject('INVALID_ARGUMENT', 'Tool arguments must be an object.');
  }

  const schema = definition.inputSchema;
  const properties = schema.properties ?? {};
  const normalized = {};
  for (const field of Object.keys(raw)) {
    if (!Object.hasOwn(properties, field)) {
      reject('INVALID_ARGUMENT', `Undeclared field ${field} is not allowed.`, field);
    }
  }
  for (const field of schema.required ?? []) {
    if (!Object.hasOwn(raw, field)) {
      reject('INVALID_ARGUMENT', `Required field ${field} is missing.`, field);
    }
  }
  for (const [field, value] of Object.entries(raw)) {
    normalized[field] = normalizeProperty(field, value, properties[field]);
  }
  normalizeTarget(normalized);
  if (Object.hasOwn(normalized, 'client')) {
    normalized.client = normalizeVisualClient(normalized.client);
  }
  return normalized;
};

export const VISUAL_CLIENT_BADGES = Object.freeze([...VISUAL_CLIENTS]);
