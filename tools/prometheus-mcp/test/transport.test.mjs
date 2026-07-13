import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { PassThrough, Readable, Writable } from 'node:stream';
import test from 'node:test';

import {
  FramingError,
  FramingParser,
  MAX_MESSAGE_BYTES,
} from '../src/framing.mjs';
import {
  McpProtocol,
  NEWEST_PROTOCOL_VERSION,
  SUPPORTED_PROTOCOL_VERSIONS,
} from '../src/protocol.mjs';
import { createStdioServer } from '../src/server.mjs';
import { BrowserSession } from '../src/session.mjs';

const request = (id, method, params = {}) => ({
  jsonrpc: '2.0',
  id,
  method,
  params,
});

const initialize = (version = NEWEST_PROTOCOL_VERSION, id = 1) =>
  request(id, 'initialize', {
    protocolVersion: version,
    capabilities: {},
    clientInfo: { name: 'transport-test', version: '1.0' },
  });

const initializeProtocol = async (protocol, emit) => {
  await protocol.handle(initialize(), emit);
  await protocol.handle(
    { jsonrpc: '2.0', method: 'notifications/initialized', params: {} },
    emit,
  );
};

const legacyFrame = (message, header = 'Content-Length') => {
  const body = JSON.stringify(message);
  return `${header}: ${Buffer.byteLength(body, 'utf8')}\r\n\r\n${body}`;
};

test('newline framing accepts fragmented UTF-8 and multiple messages', () => {
  const parser = new FramingParser();
  const first = request(1, 'ping', { value: '\ud83e\udd80' });
  const second = request(2, 'tools/list');
  const bytes = Buffer.from(
    `${JSON.stringify(first)}\r\n\n${JSON.stringify(second)}\n`,
    'utf8',
  );
  const crab = bytes.indexOf(Buffer.from('\ud83e\udd80', 'utf8'));
  const cuts = crab > 0 ? [2, crab + 1, crab + 3, bytes.length - 2] : [2, 7, 19, bytes.length - 2];
  const messages = [];
  let offset = 0;
  for (const cut of cuts) {
    messages.push(...parser.push(bytes.subarray(offset, cut)));
    offset = cut;
  }
  messages.push(...parser.push(bytes.subarray(offset)));

  assert.equal(parser.mode, 'newline');
  assert.deepEqual(messages, [first, second]);
  assert.equal(parser.encode({ jsonrpc: '2.0', id: 1, result: {} }).at(-1), 0x0a);
});

test('legacy framing accepts fragmented mixed-case headers and multiple frames', () => {
  const parser = new FramingParser();
  const first = request(3, 'ping', { value: '\ud83e\udd80' });
  const second = request(4, 'tools/list');
  const bytes = Buffer.from(
    `${legacyFrame(first, 'cOnTeNt-LeNgTh')}${legacyFrame(second)}`,
    'utf8',
  );
  const messages = [];
  for (let offset = 0; offset < bytes.length; offset += 3) {
    messages.push(...parser.push(bytes.subarray(offset, offset + 3)));
  }

  assert.equal(parser.mode, 'content-length');
  assert.deepEqual(messages, [first, second]);
  const encoded = parser.encode({ jsonrpc: '2.0', id: 3, result: {} }).toString('utf8');
  assert.match(encoded, /^Content-Length: \d+\r\n\r\n/u);
  const [header, body] = encoded.split('\r\n\r\n');
  assert.equal(Number(header.split(': ')[1]), Buffer.byteLength(body, 'utf8'));
});

test('the first message locks framing for the process', () => {
  const newline = new FramingParser();
  assert.deepEqual(newline.push(`${JSON.stringify(request(1, 'ping'))}\n`), [request(1, 'ping')]);
  assert.throws(
    () => newline.push(`${legacyFrame(request(2, 'ping'))}\n`),
    (error) => error instanceof FramingError && error.code === 'INVALID_JSON',
  );

  const legacy = new FramingParser();
  assert.deepEqual(legacy.push(legacyFrame(request(3, 'ping'))), [request(3, 'ping')]);
  assert.throws(
    () => legacy.push(`${JSON.stringify(request(4, 'ping'))}\n`),
    (error) => error instanceof FramingError && error.code === 'INVALID_HEADER',
  );
});

test('invalid, duplicate, and oversized frames are rejected deterministically', () => {
  for (const header of [
    'Content-Length: nope\r\n\r\n{}',
    'Content-Length: -1\r\n\r\n{}',
    'Content-Length: 1\r\nContent-Length: 1\r\n\r\n{}',
  ]) {
    assert.throws(
      () => new FramingParser().push(header),
      (error) => error instanceof FramingError,
      header,
    );
  }
  assert.throws(
    () => new FramingParser().push(`Content-Length: ${MAX_MESSAGE_BYTES + 1}\r\n\r\n`),
    (error) => error.code === 'MESSAGE_TOO_LARGE',
  );
  assert.throws(
    () => new FramingParser().push(Buffer.alloc(MAX_MESSAGE_BYTES + 1, 0x20)),
    (error) => error.code === 'MESSAGE_TOO_LARGE',
  );
  assert.throws(
    () => new FramingParser().push(Buffer.from([0x7b, 0x22, 0x78, 0x22, 0x3a, 0xff, 0x7d, 0x0a])),
    (error) => error.code === 'INVALID_UTF8',
  );
});

test('initialize negotiates all supported versions and newest fallback', async () => {
  for (const requested of [...SUPPORTED_PROTOCOL_VERSIONS, '2099-01-01']) {
    const output = [];
    const protocol = new McpProtocol();
    await protocol.handle(initialize(requested), (message) => output.push(message));
    assert.equal(output.length, 1);
    assert.equal(
      output[0].result.protocolVersion,
      SUPPORTED_PROTOCOL_VERSIONS.includes(requested)
        ? requested
        : NEWEST_PROTOCOL_VERSION,
    );
    assert.deepEqual(output[0].result.capabilities, { tools: { listChanged: false } });
    assert.deepEqual(output[0].result.serverInfo, {
      name: 'prometheus-mcp',
      version: '2.0.0',
    });
  }
});

test('initialized gates ping and tool operations', async () => {
  const output = [];
  const calls = [];
  const protocol = new McpProtocol({
    listTools: async () => [{ name: 'list_tabs' }],
    callTool: async (params) => {
      calls.push(params);
      return { content: [], structuredContent: { ok: true }, isError: false };
    },
  });
  const emit = (message) => output.push(message);

  await protocol.handle(request(1, 'tools/list'), emit);
  assert.equal(output.pop().error.code, -32600);
  await protocol.handle(initialize(), emit);
  await protocol.handle(request(2, 'ping'), emit);
  assert.equal(output.pop().error.code, -32600);
  await protocol.handle({ jsonrpc: '2.0', method: 'notifications/initialized', params: {} }, emit);
  await protocol.handle(request(3, 'ping'), emit);
  assert.deepEqual(output.pop().result, {});
  await protocol.handle(request(4, 'tools/list'), emit);
  assert.deepEqual(output.pop().result, { tools: [{ name: 'list_tabs' }] });
  await protocol.handle(request(5, 'tools/call', { name: 'list_tabs', arguments: {} }), emit);
  assert.equal(output.pop().result.isError, false);
  assert.deepEqual(calls, [{ name: 'list_tabs', arguments: {} }]);
});

test('malformed JSON-RPC and unknown protocol methods use JSON-RPC errors', async () => {
  const output = [];
  const protocol = new McpProtocol();
  const emit = (message) => output.push(message);
  for (const value of [null, [], {}, { jsonrpc: '1.0', id: 1, method: 'ping' }]) {
    await protocol.handle(value, emit);
    assert.equal(output.pop().error.code, -32600);
  }
  await protocol.handle(initialize(), emit);
  await protocol.handle({ jsonrpc: '2.0', method: 'notifications/initialized', params: {} }, emit);
  await protocol.handle(request(2, 'unknown/method'), emit);
  assert.equal(output.pop().error.code, -32601);
  await protocol.handle(request(3, 'tools/call', { name: 1 }), emit);
  assert.equal(output.pop().error.code, -32602);
  await protocol.handle({ jsonrpc: '2.0', method: 'unknown/notification' }, emit);
  assert.equal(output.length, 1, 'notifications never produce a response');
});

test('cancellation aborts only the matching request and emits no late response', async () => {
  const output = [];
  let release;
  let aborted = false;
  const protocol = new McpProtocol({
    callTool: (_params, { signal }) => new Promise((resolve, reject) => {
      signal.addEventListener('abort', () => {
        aborted = true;
        reject(new DOMException('cancelled private work', 'AbortError'));
      }, { once: true });
      release = () => resolve({ content: [], structuredContent: { ok: true }, isError: false });
    }),
  });
  const emit = (message) => output.push(message);
  await initializeProtocol(protocol, emit);
  output.length = 0;

  const pending = protocol.handle(
    request(9, 'tools/call', { name: 'list_tabs', arguments: {} }),
    emit,
  );
  while (!release) await new Promise((resolve) => setImmediate(resolve));
  await protocol.handle({
    jsonrpc: '2.0',
    method: 'notifications/cancelled',
    params: { requestId: 9, reason: 'private cancellation reason' },
  }, emit);
  assert.equal(aborted, true);
  await pending;
  assert.deepEqual(output, []);

  await protocol.handle(request(10, 'ping'), emit);
  assert.deepEqual(output.pop().result, {});
});

test('shutdown during initialize never reopens protocol state or emits a late response', async () => {
  let releaseInitialization;
  let markStarted;
  const started = new Promise((resolve) => { markStarted = resolve; });
  const initialization = new Promise((resolve) => { releaseInitialization = resolve; });
  let shutdowns = 0;
  const output = [];
  const protocol = new McpProtocol({
    onInitialize: async () => {
      markStarted();
      await initialization;
    },
    onShutdown: async () => { shutdowns += 1; },
  });
  const pending = protocol.handle(initialize(), (message) => output.push(message));
  await started;
  const shutdown = protocol.shutdown('SIGTERM', { graceful: true });
  releaseInitialization();
  await Promise.all([pending, shutdown]);

  assert.equal(protocol.ready, false);
  assert.equal(shutdowns, 1);
  assert.deepEqual(output, []);
});

test('stdio server emits protocol-only stdout and closes on EOF', async () => {
  const input = Readable.from([
    `${JSON.stringify(initialize())}\n`,
    `${JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized', params: {} })}\n`,
    `${JSON.stringify(request(2, 'ping'))}\n`,
  ]);
  let stdout = '';
  let stderr = '';
  let closes = 0;
  const output = new Writable({ write(chunk, _encoding, done) { stdout += chunk; done(); } });
  const errorOutput = new Writable({ write(chunk, _encoding, done) { stderr += chunk; done(); } });
  const server = createStdioServer({
    input,
    output,
    errorOutput,
    onShutdown: async ({ graceful, reason }) => {
      assert.equal(graceful, true);
      assert.equal(reason, 'EOF');
      closes += 1;
    },
  });
  await server.run();

  const frames = stdout.trim().split('\n').map((line) => JSON.parse(line));
  assert.equal(frames[0].result.protocolVersion, NEWEST_PROTOCOL_VERSION);
  assert.deepEqual(frames[1].result, {});
  assert.equal(closes, 1);
  assert.doesNotMatch(stdout, /diagnostic|private|bearer|session/iu);
  assert.equal(stderr, '');
});

test('a framing error emits once and terminates before any later legacy request', async () => {
  const poisoned = [
    'Content-Length: nope\r\n\r\n{}',
    legacyFrame(initialize(), 'Content-Length'),
  ].join('');
  let stdout = '';
  let stderr = '';
  let initializes = 0;
  let shutdownReason;
  const server = createStdioServer({
    input: Readable.from([poisoned]),
    output: new Writable({ write(chunk, _encoding, done) { stdout += chunk; done(); } }),
    errorOutput: new Writable({ write(chunk, _encoding, done) { stderr += chunk; done(); } }),
    onInitialize: async () => { initializes += 1; },
    onShutdown: async ({ reason }) => { shutdownReason = reason; },
  });
  await server.run();

  const responses = new FramingParser().push(Buffer.from(stdout, 'utf8'));
  assert.equal(responses.length, 1);
  assert.equal(responses[0].error.code, -32700);
  assert.equal(initializes, 0);
  assert.equal(shutdownReason, 'protocol-error');
  assert.match(stderr, /protocol input rejected/iu);
  assert.doesNotMatch(stderr, /nope|initialize|bearer|session/iu);
});

test('signal shutdown drains deferred initialization without a session, timer, or late output leak', async () => {
  const input = new PassThrough();
  const signalEmitter = new EventEmitter();
  let stdout = '';
  let releaseCreate;
  let markCreateStarted;
  const createStarted = new Promise((resolve) => { markCreateStarted = resolve; });
  const createResult = new Promise((resolve) => { releaseCreate = resolve; });
  let closes = 0;
  let intervals = 0;
  const session = new BrowserSession({
    nativeClient: {
      createSession: async () => {
        markCreateStarted();
        return createResult;
      },
      closeSession: async () => { closes += 1; return { ok: true }; },
      touchSession: async () => ({ ok: true }),
    },
    env: {},
    setInterval: () => { intervals += 1; return { unref() {} }; },
    clearInterval: () => {},
  });
  const server = createStdioServer({
    input,
    output: new Writable({ write(chunk, _encoding, done) { stdout += chunk; done(); } }),
    errorOutput: new PassThrough(),
    signalEmitter,
    onInitialize: (clientInfo) => session.initialize(clientInfo),
    onShutdown: ({ graceful }) => session.shutdown({ graceful }),
  });
  let runSettled = false;
  const done = server.run().then(() => { runSettled = true; });
  input.write(`${JSON.stringify(initialize())}\n`);
  await createStarted;
  signalEmitter.emit('SIGTERM');
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(runSettled, false);
  releaseCreate({ ok: true, session_id: 'late-session' });
  await done;
  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(stdout, '');
  assert.equal(intervals, 0);
  assert.equal(closes, 1);
  assert.equal(session.sessionId, null);
});

test('SIGINT and SIGTERM each request one graceful shutdown', async () => {
  for (const signal of ['SIGINT', 'SIGTERM']) {
    const input = new PassThrough();
    const signalEmitter = new EventEmitter();
    let closes = 0;
    const server = createStdioServer({
      input,
      output: new PassThrough(),
      errorOutput: new PassThrough(),
      signalEmitter,
      onShutdown: async ({ graceful, reason }) => {
        assert.equal(graceful, true);
        assert.equal(reason, signal);
        closes += 1;
      },
    });
    const done = server.run();
    signalEmitter.emit(signal);
    signalEmitter.emit(signal);
    await done;
    assert.equal(closes, 1);
  }
});
