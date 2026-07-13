import { NativeClientError } from './native-client.mjs';

export const HEARTBEAT_INTERVAL_MS = 3_000;

const truncateUtf8 = (value, maxBytes) => {
  const text = typeof value === 'string' && value.length > 0
    ? value
    : 'External MCP client';
  if (Buffer.byteLength(text, 'utf8') <= maxBytes) return text;
  let result = '';
  for (const character of text) {
    if (Buffer.byteLength(result + character, 'utf8') > maxBytes) break;
    result += character;
  }
  return result || 'External MCP client';
};

const validSessionResult = (result) =>
  result?.ok === true
  && typeof result.session_id === 'string'
  && result.session_id.length > 0
  && Buffer.byteLength(result.session_id, 'utf8') <= 128;

export class BrowserSession {
  #nativeClient;
  #env;
  #setInterval;
  #clearInterval;
  #diagnostic;
  #sessionId = null;
  #heartbeatTimer = null;
  #shutdownPromise = null;

  constructor({
    nativeClient,
    env = process.env,
    setInterval: setIntervalImplementation = globalThis.setInterval,
    clearInterval: clearIntervalImplementation = globalThis.clearInterval,
    diagnostic = () => {},
  }) {
    if (!nativeClient) throw new TypeError('A native client is required.');
    this.#nativeClient = nativeClient;
    this.#env = env;
    this.#setInterval = setIntervalImplementation;
    this.#clearInterval = clearIntervalImplementation;
    this.#diagnostic = diagnostic;
  }

  get sessionId() {
    return this.#sessionId;
  }

  async initialize(clientInfo = {}) {
    if (this.#sessionId || this.#shutdownPromise) {
      throw new NativeClientError('SESSION_INVALID');
    }
    const resumeId = this.#env.PROMETHEUS_MCP_RESUME_SESSION_ID;
    let result;
    if (resumeId !== undefined && resumeId !== '') {
      if (typeof resumeId !== 'string'
          || Buffer.byteLength(resumeId, 'utf8') > 128) {
        throw new NativeClientError('SESSION_INVALID');
      }
      result = await this.#nativeClient.resumeSession(resumeId);
    } else {
      result = await this.#nativeClient.createSession(
        truncateUtf8(clientInfo.name, 80),
      );
    }
    if (!validSessionResult(result)) {
      throw new NativeClientError('SESSION_INVALID');
    }
    this.#sessionId = result.session_id;
    this.#heartbeatTimer = this.#setInterval(
      async () => {
        try {
          const heartbeat = await this.#nativeClient.touchSession(this.#sessionId);
          if (heartbeat?.ok !== true) {
            this.#diagnostic('browser heartbeat unavailable');
          }
        } catch {
          this.#diagnostic('browser heartbeat unavailable');
        }
      },
      HEARTBEAT_INTERVAL_MS,
    );
    this.#heartbeatTimer?.unref?.();
  }

  command(route, envelope, { signal } = {}) {
    if (!this.#sessionId || this.#shutdownPromise) {
      return Promise.reject(new NativeClientError('SESSION_INVALID'));
    }
    return this.#nativeClient.command(
      this.#sessionId,
      route,
      envelope,
      { signal },
    );
  }

  health({ signal } = {}) {
    if (!this.#sessionId || this.#shutdownPromise) {
      return Promise.reject(new NativeClientError('SESSION_INVALID'));
    }
    return this.#nativeClient.health({ signal });
  }

  shutdown({ graceful = true } = {}) {
    if (this.#shutdownPromise) return this.#shutdownPromise;
    if (this.#heartbeatTimer) {
      this.#clearInterval(this.#heartbeatTimer);
      this.#heartbeatTimer = null;
    }
    const sessionId = this.#sessionId;
    this.#sessionId = null;
    this.#shutdownPromise = Promise.resolve()
      .then(async () => {
        if (graceful && sessionId) {
          try {
            await this.#nativeClient.closeSession(sessionId);
          } catch {
            this.#diagnostic('browser session close unavailable');
          }
        }
      });
    return this.#shutdownPromise;
  }
}
