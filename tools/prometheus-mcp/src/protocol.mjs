export const SUPPORTED_PROTOCOL_VERSIONS = Object.freeze([
  '2025-11-25',
  '2025-06-18',
  '2025-03-26',
  '2024-11-05',
]);
export const NEWEST_PROTOCOL_VERSION = SUPPORTED_PROTOCOL_VERSIONS[0];

const SERVER_INFO = Object.freeze({ name: 'prometheus-mcp', version: '2.0.0' });
const CAPABILITIES = Object.freeze({ tools: { listChanged: false } });

const isRecord = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

const isRequestId = (value) =>
  (typeof value === 'string' && value.length > 0)
  || (typeof value === 'number' && Number.isFinite(value));

const idKey = (id) => `${typeof id}:${String(id)}`;

const response = (id, result) => ({ jsonrpc: '2.0', id, result });
const errorResponse = (id, code, message) => ({
  jsonrpc: '2.0',
  id,
  error: { code, message },
});

const protocolError = (code, message) => ({ code, message });

const validateEmptyParams = (params) => {
  if (params === undefined) return;
  if (!isRecord(params) || Object.keys(params).length !== 0) {
    throw protocolError(-32602, 'Invalid params');
  }
};

export class McpProtocol {
  #state = 'new';
  #listTools;
  #callTool;
  #onInitialize;
  #onShutdown;
  #pending = new Map();
  #cancelled = new Set();
  #shutdownPromise = null;

  constructor({
    listTools = async () => [],
    callTool = async () => {
      throw new Error('Tool handler is unavailable.');
    },
    onInitialize = async () => {},
    onShutdown = async () => {},
  } = {}) {
    this.#listTools = listTools;
    this.#callTool = callTool;
    this.#onInitialize = onInitialize;
    this.#onShutdown = onShutdown;
  }

  get ready() {
    return this.#state === 'ready';
  }

  async handle(message, emit) {
    if (!isRecord(message) || message.jsonrpc !== '2.0'
        || typeof message.method !== 'string' || message.method.length === 0) {
      emit(errorResponse(null, -32600, 'Invalid Request'));
      return;
    }

    const hasId = Object.hasOwn(message, 'id');
    if (hasId && !isRequestId(message.id)) {
      emit(errorResponse(null, -32600, 'Invalid Request'));
      return;
    }
    const notification = !hasId;

    if (message.method === 'notifications/cancelled') {
      this.#cancel(message.params);
      return;
    }
    if (message.method === 'notifications/initialized') {
      if (this.#state === 'awaiting-initialized' && isRecord(message.params ?? {})) {
        this.#state = 'ready';
      }
      return;
    }

    if (notification) {
      return;
    }

    try {
      if (message.method === 'initialize') {
        const result = await this.#initialize(message.params);
        if (result !== null && this.#state !== 'closed') {
          emit(response(message.id, result));
        }
        return;
      }
      if (this.#state !== 'ready') {
        emit(errorResponse(message.id, -32600, 'Server is not initialized'));
        return;
      }
      if (message.method === 'ping') {
        validateEmptyParams(message.params);
        emit(response(message.id, {}));
        return;
      }
      if (message.method === 'tools/list') {
        validateEmptyParams(message.params);
        emit(response(message.id, { tools: await this.#listTools() }));
        return;
      }
      if (message.method === 'tools/call') {
        await this.#handleToolCall(message, emit);
        return;
      }
      emit(errorResponse(message.id, -32601, 'Method not found'));
    } catch (error) {
      if (error && Number.isInteger(error.code) && typeof error.message === 'string') {
        emit(errorResponse(message.id, error.code, error.message));
        return;
      }
      emit(errorResponse(message.id, -32603, 'Internal error'));
    }
  }

  shutdown(reason = 'EOF', { graceful = true } = {}) {
    if (this.#shutdownPromise) {
      return this.#shutdownPromise;
    }
    this.#state = 'closed';
    for (const { controller } of this.#pending.values()) {
      controller.abort();
    }
    this.#shutdownPromise = Promise.resolve()
      .then(() => this.#onShutdown({ reason, graceful }))
      .catch(() => {});
    return this.#shutdownPromise;
  }

  async #initialize(params) {
    if (this.#state !== 'new' || !isRecord(params)
        || typeof params.protocolVersion !== 'string'
        || !isRecord(params.capabilities)
        || !isRecord(params.clientInfo)
        || typeof params.clientInfo.name !== 'string'
        || params.clientInfo.name.length === 0) {
      throw protocolError(-32602, 'Invalid params');
    }
    this.#state = 'initializing';
    try {
      await this.#onInitialize(params.clientInfo);
    } catch {
      if (this.#state === 'closed') {
        return null;
      }
      this.#state = 'new';
      throw protocolError(-32603, 'Browser session initialization failed');
    }
    if (this.#state === 'closed') {
      return null;
    }
    this.#state = 'awaiting-initialized';
    return {
      protocolVersion: SUPPORTED_PROTOCOL_VERSIONS.includes(params.protocolVersion)
        ? params.protocolVersion
        : NEWEST_PROTOCOL_VERSION,
      capabilities: CAPABILITIES,
      serverInfo: SERVER_INFO,
    };
  }

  async #handleToolCall(message, emit) {
    const params = message.params;
    if (!isRecord(params) || typeof params.name !== 'string'
        || params.name.length === 0
        || (params.arguments !== undefined && !isRecord(params.arguments))) {
      throw protocolError(-32602, 'Invalid params');
    }
    const key = idKey(message.id);
    if (this.#pending.has(key)) {
      throw protocolError(-32600, 'Request id is already in flight');
    }
    const controller = new AbortController();
    this.#pending.set(key, { controller });
    try {
      let result;
      try {
        result = await this.#callTool(
          { name: params.name, arguments: params.arguments ?? {} },
          { signal: controller.signal },
        );
      } catch (error) {
        if (this.#cancelled.has(key) || controller.signal.aborted) {
          return;
        }
        throw error;
      }
      if (!this.#cancelled.has(key) && !controller.signal.aborted) {
        emit(response(message.id, result));
      }
    } finally {
      this.#pending.delete(key);
      this.#cancelled.delete(key);
    }
  }

  #cancel(params) {
    if (!isRecord(params) || !isRequestId(params.requestId)) {
      return;
    }
    const key = idKey(params.requestId);
    const pending = this.#pending.get(key);
    if (!pending) {
      return;
    }
    this.#cancelled.add(key);
    pending.controller.abort();
  }
}

export const jsonRpcParseError = () =>
  errorResponse(null, -32700, 'Parse error');
