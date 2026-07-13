import { lstat, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';

const DESCRIPTOR_PROTOCOL = 'prometheus-agent-v1';
const MAX_DESCRIPTOR_BYTES = 4_096;
const MAX_SECRET_BYTES = 64;
const DEFAULT_REQUEST_TIMEOUT_MS = 10_000;
const MIN_REQUEST_TIMEOUT_MS = 1_000;
const MAX_REQUEST_TIMEOUT_MS = 30_000;

export const MAX_NATIVE_RESPONSE_BYTES = 2_097_152;

const SAFE_MESSAGES = Object.freeze({
  CONFIG_INVALID: 'Native client configuration is invalid.',
  DESCRIPTOR_INVALID: 'Endpoint descriptor is invalid.',
  DESCRIPTOR_INSECURE: 'Endpoint descriptor permissions are unsafe.',
  DESCRIPTOR_UNAVAILABLE: 'Endpoint descriptor is unavailable.',
  NATIVE_CANCELLED: 'Native request was cancelled.',
  NATIVE_CONNECTION: 'Native browser endpoint is unavailable.',
  NATIVE_HTTP_ERROR: 'Native browser endpoint rejected the request.',
  NATIVE_RESPONSE_INVALID: 'Native browser response is invalid.',
  NATIVE_RESPONSE_TOO_LARGE: 'Native browser response exceeded its bound.',
  NATIVE_TIMEOUT: 'Native browser request timed out.',
  SESSION_INVALID: 'Browser session state is invalid.',
});

export class NativeClientError extends Error {
  constructor(code) {
    super(SAFE_MESSAGES[code] ?? 'Native browser request failed.');
    this.name = 'NativeClientError';
    this.code = code;
  }
}

const fail = (code) => {
  throw new NativeClientError(code);
};

const isRecord = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

const isBoundedString = (value, maxBytes) =>
  typeof value === 'string'
  && value.length > 0
  && Buffer.byteLength(value, 'utf8') <= maxBytes;

const exactKeys = (value, expected) => {
  const actual = Object.keys(value).sort();
  return actual.length === expected.length
    && actual.every((key, index) => key === expected[index]);
};

const validateDescriptor = (value) => {
  const keys = ['bearer', 'endpoint', 'instance_nonce', 'pid', 'protocol'];
  if (!isRecord(value) || !exactKeys(value, keys)) {
    fail('DESCRIPTOR_INVALID');
  }
  if (value.protocol !== DESCRIPTOR_PROTOCOL
      || !Number.isSafeInteger(value.pid) || value.pid <= 0
      || typeof value.instance_nonce !== 'string'
      || typeof value.bearer !== 'string'
      || !/^[0-9a-f]{64}$/u.test(value.instance_nonce)
      || !/^[0-9a-f]{64}$/u.test(value.bearer)
      || Buffer.byteLength(value.instance_nonce, 'utf8') !== MAX_SECRET_BYTES
      || Buffer.byteLength(value.bearer, 'utf8') !== MAX_SECRET_BYTES) {
    fail('DESCRIPTOR_INVALID');
  }
  let endpoint;
  try {
    endpoint = new URL(value.endpoint);
  } catch {
    fail('DESCRIPTOR_INVALID');
  }
  if (endpoint.protocol !== 'http:'
      || endpoint.hostname !== '127.0.0.1'
      || endpoint.port.length === 0
      || endpoint.username.length > 0
      || endpoint.password.length > 0
      || endpoint.pathname !== '/'
      || endpoint.search.length > 0
      || endpoint.hash.length > 0
      || endpoint.origin !== value.endpoint) {
    fail('DESCRIPTOR_INVALID');
  }
  return Object.freeze({ ...value });
};

export const defaultDescriptorPath = () =>
  path.join(tmpdir(), 'prometheus-mcp', 'endpoint.json');

export const resolveDescriptorPath = (env = process.env) => {
  const override = env.PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR;
  if (override === undefined || override === '') {
    return defaultDescriptorPath();
  }
  if (typeof override !== 'string' || !path.isAbsolute(override)) {
    fail('DESCRIPTOR_INVALID');
  }
  return override;
};

export const readEndpointDescriptor = async (env = process.env) => {
  const descriptorPath = resolveDescriptorPath(env);
  let metadata;
  let bytes;
  try {
    metadata = await lstat(descriptorPath);
    if (!metadata.isFile() || metadata.isSymbolicLink()
        || metadata.size <= 0 || metadata.size > MAX_DESCRIPTOR_BYTES) {
      fail('DESCRIPTOR_INVALID');
    }
    if (process.platform !== 'win32') {
      if ((metadata.mode & 0o077) !== 0) {
        fail('DESCRIPTOR_INSECURE');
      }
      if (typeof process.getuid === 'function' && metadata.uid !== process.getuid()) {
        fail('DESCRIPTOR_INSECURE');
      }
    }
    bytes = await readFile(descriptorPath);
  } catch (error) {
    if (error instanceof NativeClientError) throw error;
    fail('DESCRIPTOR_UNAVAILABLE');
  }
  let value;
  try {
    value = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
  } catch {
    fail('DESCRIPTOR_INVALID');
  }
  return validateDescriptor(value);
};

const requestTimeoutFromEnvironment = (env) => {
  const configured = env.PROMETHEUS_MCP_REQUEST_TIMEOUT_MS;
  if (configured === undefined || configured === '') {
    return DEFAULT_REQUEST_TIMEOUT_MS;
  }
  if (!/^[0-9]+$/u.test(configured)) {
    fail('CONFIG_INVALID');
  }
  const timeout = Number(configured);
  if (!Number.isSafeInteger(timeout)
      || timeout < MIN_REQUEST_TIMEOUT_MS
      || timeout > MAX_REQUEST_TIMEOUT_MS) {
    fail('CONFIG_INVALID');
  }
  return timeout;
};

const readBoundedBody = async (response) => {
  const declaredLength = response.headers?.get?.('content-length');
  if (declaredLength && /^[0-9]+$/u.test(declaredLength)
      && Number(declaredLength) > MAX_NATIVE_RESPONSE_BYTES) {
    fail('NATIVE_RESPONSE_TOO_LARGE');
  }
  if (!response.body) {
    return Buffer.alloc(0);
  }
  const reader = response.body.getReader();
  const chunks = [];
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > MAX_NATIVE_RESPONSE_BYTES) {
      await reader.cancel().catch(() => {});
      fail('NATIVE_RESPONSE_TOO_LARGE');
    }
    chunks.push(Buffer.from(value));
  }
  return Buffer.concat(chunks, total);
};

const validateSessionId = (sessionId) => {
  if (!isBoundedString(sessionId, 128)) {
    fail('SESSION_INVALID');
  }
};

const signalFromOptions = (options) => {
  if (!isRecord(options)
      || Object.keys(options).some((key) => key !== 'signal')
      || (options.signal !== undefined
        && (typeof options.signal !== 'object'
          || typeof options.signal.addEventListener !== 'function'
          || typeof options.signal.removeEventListener !== 'function'))) {
    fail('CONFIG_INVALID');
  }
  return options.signal;
};

export class NativeClient {
  #env;
  #fetch;
  #setTimeout;
  #clearTimeout;
  #requestTimeoutMs;
  #descriptor = null;

  constructor({
    env = process.env,
    fetch: fetchImplementation = globalThis.fetch,
    setTimeout: setTimeoutImplementation = globalThis.setTimeout,
    clearTimeout: clearTimeoutImplementation = globalThis.clearTimeout,
  } = {}) {
    if (typeof fetchImplementation !== 'function') {
      fail('CONFIG_INVALID');
    }
    this.#env = env;
    this.#fetch = fetchImplementation;
    this.#setTimeout = setTimeoutImplementation;
    this.#clearTimeout = clearTimeoutImplementation;
    this.#requestTimeoutMs = requestTimeoutFromEnvironment(env);
  }

  async createSession(displayLabel, options = {}) {
    if (typeof displayLabel !== 'string'
        || Buffer.byteLength(displayLabel, 'utf8') > 80) {
      throw new NativeClientError('SESSION_INVALID');
    }
    return this.#request('/v1/session/create', {
      body: { display_label: displayLabel },
      signal: signalFromOptions(options),
    });
  }

  async resumeSession(sessionId, options = {}) {
    validateSessionId(sessionId);
    return this.#request('/v1/session/resume', {
      body: { session_id: sessionId },
      signal: signalFromOptions(options),
    });
  }

  async touchSession(sessionId, options = {}) {
    validateSessionId(sessionId);
    return this.#request('/v1/session/touch', {
      body: { session_id: sessionId },
      signal: signalFromOptions(options),
    });
  }

  async closeSession(sessionId, options = {}) {
    validateSessionId(sessionId);
    return this.#request('/v1/session/close', {
      body: { session_id: sessionId },
      signal: signalFromOptions(options),
    });
  }

  async command(sessionId, route, envelope = {}, options = {}) {
    validateSessionId(sessionId);
    if (!isBoundedString(route, 80) || !/^[a-z_]+$/u.test(route)
        || !isRecord(envelope)
        || Object.keys(envelope).some((key) => !['target', 'params', 'visual'].includes(key))
        || Object.values(envelope).some((value) => !isRecord(value))) {
      throw new NativeClientError('NATIVE_RESPONSE_INVALID');
    }
    return this.#request('/v1/agent/command', {
      body: { ...envelope, route, session_id: sessionId },
      signal: signalFromOptions(options),
    });
  }

  async health(options = {}) {
    return this.#request('/v1/health', {
      method: 'GET',
      signal: signalFromOptions(options),
    });
  }

  async #loadDescriptor(force = false) {
    if (!this.#descriptor || force) {
      this.#descriptor = await readEndpointDescriptor(this.#env);
    }
    return this.#descriptor;
  }

  async #request(requestPath, { method = 'POST', body, signal } = {}) {
    const descriptor = await this.#loadDescriptor();
    try {
      return await this.#attempt(descriptor, requestPath, { method, body, signal });
    } catch (error) {
      if (!(error instanceof NativeClientError) || error.code !== 'NATIVE_CONNECTION') {
        throw error;
      }
      let refreshed;
      try {
        refreshed = await this.#loadDescriptor(true);
      } catch {
        throw error;
      }
      if (refreshed.instance_nonce === descriptor.instance_nonce
          && refreshed.endpoint === descriptor.endpoint
          && refreshed.bearer === descriptor.bearer) {
        throw error;
      }
      return this.#attempt(refreshed, requestPath, { method, body, signal });
    }
  }

  async #attempt(descriptor, requestPath, { method, body, signal }) {
    const controller = new AbortController();
    let timedOut = false;
    let callerCancelled = signal?.aborted === true;
    const cancelFromCaller = () => {
      callerCancelled = true;
      controller.abort();
    };
    signal?.addEventListener('abort', cancelFromCaller, { once: true });
    if (callerCancelled) {
      signal?.removeEventListener('abort', cancelFromCaller);
      fail('NATIVE_CANCELLED');
    }
    const timer = this.#setTimeout(() => {
      timedOut = true;
      controller.abort();
    }, this.#requestTimeoutMs);
    timer?.unref?.();

    try {
      const headers = { Authorization: `Bearer ${descriptor.bearer}` };
      const options = {
        method,
        headers,
        signal: controller.signal,
        redirect: 'error',
      };
      if (body !== undefined) {
        headers['Content-Type'] = 'application/json';
        options.body = JSON.stringify(body);
      }
      let response;
      try {
        response = await this.#fetch(`${descriptor.endpoint}${requestPath}`, options);
      } catch {
        if (timedOut) fail('NATIVE_TIMEOUT');
        if (callerCancelled || signal?.aborted) fail('NATIVE_CANCELLED');
        fail('NATIVE_CONNECTION');
      }
      if (!response || typeof response.status !== 'number') {
        fail('NATIVE_RESPONSE_INVALID');
      }
      if (response.status < 200 || response.status >= 300) {
        fail('NATIVE_HTTP_ERROR');
      }
      let bytes;
      try {
        bytes = await readBoundedBody(response);
      } catch (error) {
        if (error instanceof NativeClientError) throw error;
        if (timedOut) fail('NATIVE_TIMEOUT');
        if (callerCancelled || signal?.aborted) fail('NATIVE_CANCELLED');
        fail('NATIVE_RESPONSE_INVALID');
      }
      let result;
      try {
        result = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
      } catch {
        fail('NATIVE_RESPONSE_INVALID');
      }
      if (!isRecord(result) || typeof result.ok !== 'boolean') {
        fail('NATIVE_RESPONSE_INVALID');
      }
      return result;
    } finally {
      this.#clearTimeout(timer);
      signal?.removeEventListener('abort', cancelFromCaller);
    }
  }
}
