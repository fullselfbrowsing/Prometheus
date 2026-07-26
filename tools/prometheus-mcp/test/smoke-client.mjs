#!/usr/bin/env node

import { spawn } from 'node:child_process';
import {
  chmod,
  lstat,
  mkdir,
  open,
  readFile,
  writeFile,
} from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export const RPC_TIMEOUT_MS = 30_000;
export const DIAGNOSTIC_KEYS = Object.freeze([
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

const PROTOCOL_VERSION = '2025-06-18';
const MAX_STDOUT_BUFFER_BYTES = 4 * 1024 * 1024;
const MAX_STDERR_BYTES = 1024 * 1024;
const SESSION_GRACE_MS = 10_000;
const DEFAULT_EXPIRY_WAIT_MS = 11_000;
const STATUS_VALUES = new Set(['ready', 'degraded', 'not_ready', 'unavailable']);
const LATER_DIAGNOSTICS = new Set(['extensions']);
const PHASE20_PROVIDER_ID = 'phase20-smoke-local';
const PHASE20_MODEL_ID = 'phase20-fixture-model';
const MAX_SAFE_TITLE_BYTES = 256;
let liveSmokeStage = 'startup';

const requireCondition = (condition, message) => {
  if (!condition) throw new Error(message);
};

const isRecord = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

const exactKeys = (value, keys) => {
  if (!isRecord(value)) return false;
  const actual = Object.keys(value).sort();
  const expected = [...keys].sort();
  return actual.length === expected.length
    && actual.every((key, index) => key === expected[index]);
};

const slugify = (value) => {
  const slug = String(value).toLowerCase().replaceAll(/[^a-z0-9]+/gu, '-').replaceAll(/^-|-$/gu, '');
  return slug || 'bridge';
};

const hasSameOriginAndPath = (value, expected) => {
  try {
    const observed = new URL(value);
    return observed.origin === expected.origin
      && observed.pathname === expected.pathname;
  } catch {
    return false;
  }
};

const parseSnapshotTargets = (snapshotResult) => {
  const serialized = snapshotResult?.page?.dom_snapshot_json;
  requireCondition(
    typeof serialized === 'string' && serialized.length > 0 && serialized.length <= 200_000,
    'DOM snapshot did not return bounded JSON.',
  );
  let nodes;
  try {
    nodes = JSON.parse(serialized);
  } catch {
    throw new Error('DOM snapshot JSON could not be parsed.');
  }
  requireCondition(Array.isArray(nodes) && nodes.length > 0 && nodes.length <= 1_000, 'DOM snapshot node inventory is invalid.');

  const target = (marker, tag) => {
    const matches = nodes.filter((node) => isRecord(node)
      && node.tag === tag
      && [node.name, node.text_snippet, node.selector_hint]
        .some((value) => typeof value === 'string' && value.includes(marker)));
    requireCondition(
      matches.length === 1,
      `DOM snapshot target ${tag} matched ${matches.length} nodes.`,
    );
    const [node] = matches;
    requireCondition(
      typeof node.ref === 'string' && node.ref.length > 0 && node.ref.length <= 4_096
        && typeof node.frame === 'string' && node.frame.length > 0 && node.frame.length <= 4_096,
      `DOM snapshot target ${tag} did not return an exact document-scoped handle.`,
    );
    return Object.freeze({ ref: node.ref, document_token: node.frame });
  };

  return Object.freeze({
    text: target('fixture text target', 'paragraph'),
    attribute: target('attribute fixture target', 'paragraph'),
    input: target('fixture input target', 'form_control'),
    button: target('mutation button target', 'form_control'),
    status: target('mutation status target', 'form_control'),
  });
};

const waitForExit = (child, milliseconds) => new Promise((resolve, reject) => {
  if (child.exitCode !== null || child.signalCode !== null) {
    resolve({ code: child.exitCode, signal: child.signalCode });
    return;
  }
  const timer = setTimeout(() => {
    cleanup();
    reject(new Error('Bridge process did not exit within its teardown bound.'));
  }, milliseconds);
  timer.unref?.();
  const onExit = (code, signal) => {
    cleanup();
    resolve({ code, signal });
  };
  const cleanup = () => {
    clearTimeout(timer);
    child.off('exit', onExit);
  };
  child.once('exit', onExit);
});

export class BridgeProcess {
  #bridgeEntry;
  #env;
  #label;
  #captureDirectory;
  #child;
  #nextId = 1;
  #pending = new Map();
  #stdoutBuffer = Buffer.alloc(0);
  #stderr = '';
  #transcript = [];
  #responses = [];
  #closed = false;
  #fatalError = null;
  #capturePromise = null;

  constructor({ bridgeEntry, env, label, captureDirectory }) {
    requireCondition(path.isAbsolute(bridgeEntry), 'Bridge entry must be absolute.');
    requireCondition(path.isAbsolute(captureDirectory), 'Capture directory must be absolute.');
    this.#bridgeEntry = bridgeEntry;
    this.#env = { ...env };
    this.#label = String(label);
    this.#captureDirectory = captureDirectory;
    this.#child = spawn(process.execPath, [this.#bridgeEntry], {
      cwd: path.dirname(this.#bridgeEntry),
      env: this.#env,
      stdio: ['pipe', 'pipe', 'pipe'],
      windowsHide: true,
    });
    this.#child.stdout.on('data', (chunk) => this.#onStdout(chunk));
    this.#child.stderr.on('data', (chunk) => {
      if (Buffer.byteLength(this.#stderr, 'utf8') < MAX_STDERR_BYTES) {
        this.#stderr += chunk.toString('utf8').slice(
          0,
          MAX_STDERR_BYTES - Buffer.byteLength(this.#stderr, 'utf8'),
        );
      }
    });
    this.#child.once('error', () => this.#fail('Bridge process could not start.'));
    this.#child.once('exit', (code, signal) => {
      if (!this.#closed && this.#pending.size > 0) {
        this.#fail(`Bridge process exited before completing RPC (${code ?? signal ?? 'unknown'}).`);
      }
    });
  }

  get pid() {
    return this.#child.pid;
  }

  get capturedOutput() {
    return `${this.#transcript.map((frame) => JSON.stringify(frame)).join('\n')}\n${this.#stderr}`;
  }

  assertProtocolSafety(deniedValues, allowedToolResultValues = []) {
    assertSafeProtocolResponses(
      this.#responses,
      deniedValues,
      allowedToolResultValues,
    );
  }

  async initialize() {
    const result = await this.request('initialize', {
      protocolVersion: PROTOCOL_VERSION,
      capabilities: {},
      clientInfo: { name: this.#label, version: '1.0' },
    });
    requireCondition(
      result?.protocolVersion === PROTOCOL_VERSION,
      'Bridge negotiated an unexpected MCP protocol version.',
    );
    requireCondition(
      result?.serverInfo?.name === 'prometheus-mcp',
      'Bridge returned an unexpected server identity.',
    );
    this.notify('notifications/initialized', {});
    return result;
  }

  request(method, params = {}) {
    requireCondition(!this.#closed, 'Bridge process is closed.');
    requireCondition(!this.#fatalError, this.#fatalError?.message ?? 'Bridge process failed.');
    const id = this.#nextId++;
    const message = { jsonrpc: '2.0', id, method, params };
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.#pending.delete(id);
        reject(new Error(`MCP RPC ${method} exceeded ${RPC_TIMEOUT_MS}ms.`));
      }, RPC_TIMEOUT_MS);
      timer.unref?.();
      this.#pending.set(id, {
        method,
        resolve: (value) => {
          clearTimeout(timer);
          resolve(value);
        },
        reject: (error) => {
          clearTimeout(timer);
          reject(error);
        },
      });
      this.#write(message).catch((error) => {
        const pending = this.#pending.get(id);
        this.#pending.delete(id);
        pending?.reject(error);
      });
    });
  }

  notify(method, params = {}) {
    requireCondition(!this.#closed, 'Bridge process is closed.');
    void this.#write({ jsonrpc: '2.0', method, params }).catch(() => {
      this.#fail('Bridge notification could not be written.');
    });
  }

  callTool(name, arguments_ = {}) {
    return this.request('tools/call', { name, arguments: arguments_ });
  }

  async close({ graceful }) {
    if (this.#closed) {
      await this.#capturePromise;
      return;
    }
    this.#closed = true;
    if (graceful) {
      this.#child.stdin.end();
    } else {
      this.#child.kill('SIGKILL');
    }
    try {
      const exit = await waitForExit(this.#child, 5_000);
      if (graceful) {
        requireCondition(
          exit.code === 0 && exit.signal === null,
          'Graceful bridge process did not exit cleanly.',
        );
      }
    } catch (error) {
      this.#child.kill('SIGKILL');
      await waitForExit(this.#child, 2_000).catch(() => {});
      if (graceful) throw error;
    } finally {
      this.#rejectPending(new Error('Bridge process closed.'));
      this.#capturePromise = this.#writeCapture();
      await this.#capturePromise;
    }
  }

  async #write(message) {
    const frame = `${JSON.stringify(message)}\n`;
    await new Promise((resolve, reject) => {
      this.#child.stdin.write(frame, 'utf8', (error) => error ? reject(error) : resolve());
    });
  }

  #onStdout(chunk) {
    if (this.#fatalError) return;
    this.#stdoutBuffer = Buffer.concat([this.#stdoutBuffer, chunk]);
    if (this.#stdoutBuffer.length > MAX_STDOUT_BUFFER_BYTES) {
      this.#fail('Bridge protocol stdout exceeded its frame bound.');
      return;
    }
    for (;;) {
      const newline = this.#stdoutBuffer.indexOf(0x0a);
      if (newline < 0) return;
      const bytes = this.#stdoutBuffer.subarray(0, newline);
      this.#stdoutBuffer = this.#stdoutBuffer.subarray(newline + 1);
      if (bytes.length === 0) continue;
      let frame;
      try {
        frame = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
      } catch {
        this.#fail('Bridge protocol stdout was not newline JSON-RPC.');
        return;
      }
      if (!isRecord(frame) || frame.jsonrpc !== '2.0'
          || (!Object.hasOwn(frame, 'result') && !Object.hasOwn(frame, 'error'))
          || !Number.isSafeInteger(frame.id)) {
        this.#fail('Bridge protocol stdout contained a non-response frame.');
        return;
      }
      const pending = this.#pending.get(frame.id);
      if (!pending) {
        this.#fail('Bridge protocol stdout contained an unknown response id.');
        return;
      }
      this.#pending.delete(frame.id);
      this.#responses.push({ method: pending.method, frame });
      this.#transcript.push({
        jsonrpc: '2.0',
        id: frame.id,
        kind: Object.hasOwn(frame, 'error') ? 'error' : 'result',
        method: pending.method,
      });
      if (Object.hasOwn(frame, 'error')) {
        pending.reject(new Error(`MCP JSON-RPC error ${frame.error?.code ?? 'unknown'}.`));
      } else {
        pending.resolve(frame.result);
      }
    }
  }

  #fail(message) {
    if (this.#fatalError) return;
    this.#fatalError = new Error(message);
    this.#rejectPending(this.#fatalError);
    this.#child.kill('SIGKILL');
  }

  #rejectPending(error) {
    for (const pending of this.#pending.values()) pending.reject(error);
    this.#pending.clear();
  }

  async #writeCapture() {
    await mkdir(this.#captureDirectory, { recursive: true, mode: 0o700 });
    const stem = slugify(this.#label);
    const protocol = this.#transcript.map((frame) => JSON.stringify(frame)).join('\n');
    await writeFile(
      path.join(this.#captureDirectory, `${stem}.protocol.jsonl`),
      protocol.length > 0 ? `${protocol}\n` : '',
      { mode: 0o600 },
    );
    await writeFile(
      path.join(this.#captureDirectory, `${stem}.stderr.log`),
      this.#stderr,
      { mode: 0o600 },
    );
  }
}

export const assertCompatibilityInventory = (tools, expectedNames) => {
  requireCondition(Array.isArray(tools), 'tools/list did not return a tool array.');
  requireCondition(tools.length === 90, 'tools/list must expose exactly 90 names.');
  const names = tools.map((tool) => tool?.name);
  requireCondition(
    names.every((name) => typeof name === 'string') && new Set(names).size === 90,
    'tools/list must expose 90 unique string names.',
  );
  const actual = [...names].sort();
  const expected = [...expectedNames].sort();
  requireCondition(
    expected.length === 90
      && actual.every((name, index) => name === expected[index]),
    'tools/list does not match the exact 90-name compatibility inventory.',
  );
};

export const assertDiagnosticInventory = (result) => {
  requireCondition(result?.ok === true, 'Diagnostics did not succeed.');
  requireCondition(
    Array.isArray(result.components) && result.components.length === 10,
    'Diagnostics must contain exactly ten components.',
  );
  requireCondition(
    result.components.every((component, index) =>
      isRecord(component)
      && component.key === DIAGNOSTIC_KEYS[index]
      && STATUS_VALUES.has(component.status)
      && typeof component.reason === 'string'
      && component.reason.length > 0
      && typeof component.next_action === 'string'
      && component.next_action.length > 0),
    'Diagnostics did not match the closed ten-component schema.',
  );
  for (const component of result.components) {
    if (LATER_DIAGNOSTICS.has(component.key)) {
      requireCondition(
        component.status === 'not_ready',
        `${component.key} must remain not_ready until its owning phase.`,
      );
    }
  }
};

export const assertRemovedToolResult = (result) => {
  const error = result?.error;
  requireCondition(error?.code === 'TOOL_REMOVED', 'Removed tool must return TOOL_REMOVED.');
  requireCondition(
    error.removed_since === '0.9.0',
    'Removed tool must record removed_since 0.9.0.',
  );
  requireCondition(
    error.observed_as_typed_stubs_as_of === '0.9.72',
    'Removed tool must record observed_as_typed_stubs_as_of 0.9.72.',
  );
  requireCondition(
    !Object.hasOwn(error, 'observed_absent_as_of'),
    'Removed compatibility stubs must not claim observed_absent_as_of.',
  );
  requireCondition(
    Array.isArray(error.replacements)
      && ['visual_reason', 'client', 'is_final'].every((field) => error.replacements.includes(field)),
    'Removed tool must provide per-action visual replacements.',
  );
};

export const assertSafeCapturedOutput = (captured, deniedValues) => {
  for (const value of deniedValues) {
    if (typeof value === 'string' && value.length > 0 && captured.includes(value)) {
      throw new Error('captured output contains a denied private value.');
    }
  }
};

export const assertSafeProtocolResponses = (
  responses,
  deniedValues,
  allowedToolResultValues = [],
) => {
  for (const response of responses) {
    requireCondition(
      isRecord(response)
        && typeof response.method === 'string'
        && isRecord(response.frame),
      'Captured protocol response is invalid.',
    );
    const serialized = JSON.stringify(response.frame);
    for (const value of deniedValues) {
      if (typeof value === 'string' && value.length > 0 && serialized.includes(value)) {
        throw new Error('protocol response contains a denied private value.');
      }
    }
    for (const value of allowedToolResultValues) {
      if (typeof value !== 'string' || value.length === 0 || !serialized.includes(value)) continue;
      requireCondition(
        response.method === 'tools/call'
          && Object.hasOwn(response.frame, 'result')
          && !Object.hasOwn(response.frame, 'error'),
        'Requested page content escaped a successful tool result.',
      );
    }
  }
};

const unwrapToolResult = (result, name) => {
  requireCondition(isRecord(result), `${name} did not return an MCP tool result.`);
  requireCondition(
    Array.isArray(result.content) && result.content.length === 1
      && result.content[0]?.type === 'text'
      && typeof result.content[0]?.text === 'string'
      && isRecord(result.structuredContent)
      && typeof result.isError === 'boolean',
    `${name} returned a malformed MCP tool result.`,
  );
  let parsed;
  try {
    parsed = JSON.parse(result.content[0].text);
  } catch {
    throw new Error(`${name} text content was not JSON.`);
  }
  requireCondition(
    JSON.stringify(parsed) === JSON.stringify(result.structuredContent),
    `${name} text and structured results diverged.`,
  );
  return result.structuredContent;
};

const expectToolSuccess = async (bridge, name, arguments_) => {
  const result = await bridge.callTool(name, arguments_);
  const structured = unwrapToolResult(result, name);
  if (result.isError !== false || structured.ok !== true) {
    liveSmokeStage = `${liveSmokeStage}_${String(
      structured.error_code ?? structured.error?.code ?? 'unknown',
    ).toLowerCase().replaceAll(/[^a-z0-9]+/gu, '_')}`;
  }
  requireCondition(
    result.isError === false && structured.ok === true,
    `${name} failed (${structured.error_code ?? structured.error?.code ?? 'unknown'}).`,
  );
  return structured;
};

const expectToolFailure = async (bridge, name, arguments_) => {
  const result = await bridge.callTool(name, arguments_);
  const structured = unwrapToolResult(result, name);
  requireCondition(result.isError === true && structured.ok === false, `${name} unexpectedly succeeded.`);
  return structured;
};

const runtimePayload = (structured, name) => {
  requireCondition(
    structured?.ok === true
      && structured.error_code === 'NONE'
      && isRecord(structured.result),
    `${name} did not return a successful native runtime payload.`,
  );
  return structured.result;
};

const assertSafeTaskView = (task, promptSentinel) => {
  requireCondition(
    isRecord(task)
      && typeof task.task_id === 'string'
      && task.task_id.length > 0
      && typeof task.safe_title === 'string'
      && task.safe_title.length > 0
      && Buffer.byteLength(task.safe_title, 'utf8') <= MAX_SAFE_TITLE_BYTES,
    'Runtime task did not contain a bounded public identity and safe title.',
  );
  const serialized = JSON.stringify(task);
  requireCondition(
    !Object.hasOwn(task, 'prompt')
      && !serialized.includes('"prompt"')
      && !serialized.includes(promptSentinel),
    'Runtime task exposed its raw prompt instead of a safe title.',
  );
  return task;
};

const eventually = async (callback, {
  timeoutMs = 15_000,
  intervalMs = 150,
} = {}) => {
  const deadline = Date.now() + timeoutMs;
  let lastError;
  while (Date.now() < deadline) {
    try {
      const value = await callback();
      if (value !== undefined && value !== false) return value;
    } catch (error) {
      lastError = error;
    }
    await new Promise((resolve) => setTimeout(resolve, intervalMs));
  }
  throw lastError ?? new Error('Live condition did not become ready before its deadline.');
};

const discoverModelsThroughStatus = async (bridge, providerId) => {
  const started = runtimePayload(await expectToolSuccess(
    bridge,
    'discover_models',
    { provider_id: providerId },
  ), 'discover_models');
  requireCondition(
    typeof started.operation_id === 'string'
      && /^[1-9][0-9]{0,19}$/u.test(started.operation_id)
      && Array.isArray(started.models)
      && typeof started.pending === 'boolean',
    'Model discovery did not return a bounded polling operation.',
  );
  if (!started.pending) return started;
  return eventually(async () => {
    const status = runtimePayload(await expectToolSuccess(
      bridge,
      'discover_models',
      { operation_id: started.operation_id },
    ), 'discover_models');
    requireCondition(
      status.operation_id === started.operation_id
        && Array.isArray(status.models)
        && typeof status.pending === 'boolean',
      'Model discovery status did not preserve its polling operation.',
    );
    return status.pending ? false : status;
  });
};

const readDescriptor = async (descriptorPath) => {
  const metadata = await lstat(descriptorPath);
  requireCondition(metadata.isFile() && !metadata.isSymbolicLink(), 'Descriptor must be a regular file.');
  if (process.platform !== 'win32') {
    requireCondition((metadata.mode & 0o777) === 0o600, 'Descriptor mode must be 0600.');
  }
  const descriptor = JSON.parse(await readFile(descriptorPath, 'utf8'));
  requireCondition(
    exactKeys(descriptor, ['bearer', 'endpoint', 'instance_nonce', 'pid', 'protocol'])
      && descriptor.protocol === 'prometheus-agent-v1'
      && /^http:\/\/127\.0\.0\.1:[0-9]+$/u.test(descriptor.endpoint)
      && /^[0-9a-f]{64}$/u.test(descriptor.bearer)
      && /^[0-9a-f]{64}$/u.test(descriptor.instance_nonce),
    'Endpoint descriptor did not match the closed gateway schema.',
  );
  return descriptor;
};

const gatewayRequest = async (descriptor, requestPath, body) => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), RPC_TIMEOUT_MS);
  timeout.unref?.();
  try {
    const options = {
      method: body === undefined ? 'GET' : 'POST',
      headers: { Authorization: `Bearer ${descriptor.bearer}` },
      redirect: 'error',
      signal: controller.signal,
    };
    if (body !== undefined) {
      options.headers['Content-Type'] = 'application/json';
      options.body = JSON.stringify(body);
    }
    const response = await fetch(`${descriptor.endpoint}${requestPath}`, options);
    requireCondition(response.ok, `Gateway ${requestPath} returned HTTP ${response.status}.`);
    return await response.json();
  } finally {
    clearTimeout(timeout);
  }
};

const gatewayAgentCommand = async (
  descriptor,
  sessionId,
  route,
  target,
) => {
  const body = { route, session_id: sessionId };
  if (target !== undefined) body.target = target;
  const result = await gatewayRequest(descriptor, '/v1/agent/command', body);
  requireCondition(
    result?.ok === true && result.error_code === 'NONE',
    `Agent compatibility route ${route} failed (${result?.error_code ?? 'unknown'}).`,
  );
  return result;
};

const gatewaySupervision = async (
  descriptor,
  operation,
  params,
  expectedError,
) => {
  const response = await gatewayRequest(descriptor, '/v1/supervision', {
    operation,
    params,
  });
  requireCondition(
    response?.operation === operation && isRecord(response.result),
    `Supervision ${operation} returned an invalid closed response.`,
  );
  const failureDetail = `${response.message ?? ''} ${response.recovery ?? ''}`;
  const failureKind = failureDetail.includes('unknown or expired')
    ? 'unknown_session'
    : failureDetail.includes('shutting down')
      ? 'shutdown'
      : '';
  if (expectedError) {
    if (response.ok !== false || response.error_code !== expectedError) {
      liveSmokeStage = `${liveSmokeStage}_${String(
        response.error_code ?? 'unknown',
      ).toLowerCase().replaceAll(/[^a-z0-9]+/gu, '_')}${
        failureKind ? `_${failureKind}` : ''
      }`;
    }
    requireCondition(
      response.ok === false && response.error_code === expectedError,
      `Supervision ${operation} did not fail with ${expectedError}.`,
    );
  } else {
    if (response.ok !== true || response.error_code !== 'NONE') {
      liveSmokeStage = `${liveSmokeStage}_${String(
        response.error_code ?? 'unknown',
      ).toLowerCase().replaceAll(/[^a-z0-9]+/gu, '_')}${
        failureKind ? `_${failureKind}` : ''
      }`;
    }
    requireCondition(
      response.ok === true && response.error_code === 'NONE',
      `Supervision ${operation} failed (${response.error_code ?? 'unknown'}).`,
    );
  }
  return response;
};

const dashboardAuthority = (response, operation) => {
  const authority = response?.result;
  requireCondition(
    typeof authority?.dashboard_session === 'string'
      && authority.dashboard_session.length > 0,
    `Supervision ${operation} omitted dashboard authority.`,
  );
  if (operation !== 'redeem') {
    requireCondition(
      typeof authority.document_epoch === 'string'
        && authority.document_epoch.length > 0
        && Number.isSafeInteger(authority.sequence)
        && authority.sequence > 0,
      `Supervision ${operation} omitted its exact stream cursor.`,
    );
  }
  return authority;
};

const endDashboardSession = async (descriptor, dashboardSession) => {
  const response = await gatewayRequest(descriptor, '/v1/supervision', {
    operation: 'end',
    params: { dashboard_session: dashboardSession },
  });
  requireCondition(
    response?.operation === 'end' && isRecord(response.result),
    'Supervision end returned an invalid closed response.',
  );
  const explicitlyEnded = response.ok === true
    && response.error_code === 'NONE'
    && response.result.ended === true;
  const alreadyTerminal = response.ok === false
    && response.error_code === 'UNAVAILABLE'
    && Object.keys(response.result).length === 0;
  requireCondition(
    explicitlyEnded || alreadyTerminal,
    `Supervision end returned an invalid terminal result (${
      response.error_code ?? 'unknown'
    }).`,
  );
  return explicitlyEnded;
};

const assertCompatibilityHasNoDashboardAuthority = (value, route) => {
  const serialized = JSON.stringify(value);
  requireCondition(
    !serialized.includes('dashboard_session')
      && !serialized.includes('document_epoch')
      && !serialized.includes('"sequence"'),
    `${route} exposed dashboard authority through the Agent compatibility route.`,
  );
};

const createRawSession = async (descriptor, displayLabel) => {
  const result = await gatewayRequest(descriptor, '/v1/session/create', {
    display_label: displayLabel,
  });
  requireCondition(
    result?.ok === true
      && typeof result.session_id === 'string'
      && result.session_id.length > 0
      && result.reconnect_grace_ms === SESSION_GRACE_MS,
    'Browser did not issue a bounded resumable session.',
  );
  return result.session_id;
};

const bridgeEnvironment = (baseEnvironment, descriptorPath, resumeSessionId) => {
  const env = { ...baseEnvironment };
  for (const key of Object.keys(env)) {
    if (key.startsWith('PROMETHEUS_MCP_SMOKE_')) delete env[key];
  }
  env.PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR = descriptorPath;
  env.PROMETHEUS_MCP_REQUEST_TIMEOUT_MS = String(RPC_TIMEOUT_MS);
  if (resumeSessionId) {
    env.PROMETHEUS_MCP_RESUME_SESSION_ID = resumeSessionId;
  } else {
    delete env.PROMETHEUS_MCP_RESUME_SESSION_ID;
  }
  return env;
};

const loadExpectedNames = async () => {
  const [frozen, current] = await Promise.all([
    readFile(new URL('fixtures/frozen-v1-tools.json', import.meta.url), 'utf8'),
    readFile(new URL('fixtures/current-fsb-tools.json', import.meta.url), 'utf8'),
  ]);
  return [...new Set([
    ...JSON.parse(frozen).names,
    ...JSON.parse(current).names,
  ])].sort();
};

const writePrivateDenylist = async (file, values) => {
  const handle = await open(file, 'wx', 0o600);
  try {
    await handle.writeFile(`${JSON.stringify(values)}\n`, 'utf8');
    await handle.sync();
  } finally {
    await handle.close();
  }
  await chmod(file, 0o600);
};

const runLiveSmoke = async () => {
  const descriptorPath = process.env.PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR;
  const fixtureUrl = process.env.PROMETHEUS_MCP_FIXTURE_URL;
  const captureDirectory = process.env.PROMETHEUS_MCP_SMOKE_CAPTURE_DIR;
  const denylistFile = process.env.PROMETHEUS_MCP_SMOKE_DENYLIST_FILE;
  const profilePath = process.env.PROMETHEUS_MCP_SMOKE_PROFILE_PATH;
  let supervisionChallenge =
    process.env.PROMETHEUS_MCP_SMOKE_SUPERVISION_CHALLENGE;
  const bridgeEntry = path.resolve(
    process.env.PROMETHEUS_MCP_BRIDGE_ENTRY
      ?? new URL('../bin/prometheus-mcp.mjs', import.meta.url).pathname,
  );
  for (const [name, value] of Object.entries({
    PROMETHEUS_MCP_ENDPOINT_DESCRIPTOR: descriptorPath,
    PROMETHEUS_MCP_FIXTURE_URL: fixtureUrl,
    PROMETHEUS_MCP_SMOKE_CAPTURE_DIR: captureDirectory,
    PROMETHEUS_MCP_SMOKE_DENYLIST_FILE: denylistFile,
    PROMETHEUS_MCP_SMOKE_PROFILE_PATH: profilePath,
    PROMETHEUS_MCP_SMOKE_SUPERVISION_CHALLENGE: supervisionChallenge,
  })) {
    requireCondition(typeof value === 'string' && value.length > 0, `${name} is required.`);
  }
  requireCondition(path.isAbsolute(descriptorPath), 'Descriptor path must be absolute.');
  requireCondition(path.isAbsolute(captureDirectory), 'Capture directory must be absolute.');
  requireCondition(path.isAbsolute(denylistFile), 'Denylist file must be absolute.');
  requireCondition(path.isAbsolute(profilePath), 'Profile path must be absolute.');
  requireCondition(
    /^[0-9a-f]{64}$/u.test(supervisionChallenge),
    'Supervision challenge must be exactly 256 bits of lowercase hex.',
  );
  delete process.env.PROMETHEUS_MCP_SMOKE_SUPERVISION_CHALLENGE;
  const supervisionChallengeBuffer =
    Buffer.from(supervisionChallenge, 'utf8');
  const supervisionChallengeSentinel =
    supervisionChallengeBuffer.toString('utf8');
  supervisionChallenge = '';
  const fixture = new URL(fixtureUrl);
  requireCondition(
    fixture.protocol === 'http:'
      && ['127.0.0.1', 'localhost', '[::1]'].includes(fixture.hostname),
    'Fixture must use loopback HTTP.',
  );

  const expiryWait = Number(
    process.env.PROMETHEUS_MCP_SMOKE_EXPIRY_WAIT_MS ?? DEFAULT_EXPIRY_WAIT_MS,
  );
  requireCondition(
    Number.isInteger(expiryWait) && expiryWait > SESSION_GRACE_MS && expiryWait <= 15_000,
    'Expiry wait must cross the ten-second grace within its deterministic bound.',
  );
  await mkdir(captureDirectory, { recursive: true, mode: 0o700 });
  const descriptor = await readDescriptor(descriptorPath);
  const expectedNames = await loadExpectedNames();
  const visualReason = `private-smoke-reason-${process.pid}`;
  const typedText = `private-smoke-input-${process.pid}`;
  const primaryPromptSentinel = `phase20-primary-prompt-${process.pid}`;
  const secondPromptSentinel = `phase20-second-prompt-${process.pid}`;
  const providerSecretSentinel = `phase20-provider-secret-${process.pid}`;
  const sessionIds = [];
  const pairingCodes = [];
  const dashboardSessions = [];
  const bridges = [];
  let primary;
  let second;

  const createBridge = (label, resumeSessionId) => {
    const bridge = new BridgeProcess({
      bridgeEntry,
      env: bridgeEnvironment(process.env, descriptorPath, resumeSessionId),
      label,
      captureDirectory,
    });
    bridges.push(bridge);
    return bridge;
  };

  const submitStatusCancel = async (bridge, promptSentinel, aliases = false) => {
    const submitName = aliases ? 'submit_task' : 'run_task';
    const statusName = aliases ? 'task_status' : 'get_task_status';
    const cancelName = aliases ? 'cancel_task' : 'stop_task';
    const logsName = aliases ? 'list_runtime_logs' : 'get_logs';
    const submitted = runtimePayload(await expectToolSuccess(bridge, submitName, {
      prompt: `Inspect the fixture. token ${promptSentinel}`,
      requested_execution: 'local',
      provider_id: PHASE20_PROVIDER_ID,
    }), submitName);
    const task = assertSafeTaskView(submitted.task, promptSentinel);
    requireCondition(
      task.state === 'queued'
        && task.origin === 'mcp'
        && task.effective_execution === 'local',
      'Runtime submission did not preserve queued MCP/local provenance.',
    );

    const status = runtimePayload(await expectToolSuccess(bridge, statusName, {
      task_id: task.task_id,
    }), statusName);
    requireCondition(
      assertSafeTaskView(status.task, promptSentinel).task_id === task.task_id,
      'Runtime status did not return the caller-owned task.',
    );
    const tasks = runtimePayload(await expectToolSuccess(bridge, 'list_tasks', {
      limit: 20,
    }), 'list_tasks');
    requireCondition(
      Array.isArray(tasks.tasks)
        && tasks.tasks.some((item) => item?.task_id === task.task_id),
      'Runtime task list omitted the caller-owned task.',
    );

    const cancelled = runtimePayload(await expectToolSuccess(bridge, cancelName, {
      task_id: task.task_id,
    }), cancelName);
    requireCondition(
      assertSafeTaskView(cancelled.task, promptSentinel).state === 'cancelled',
      'Runtime cancellation did not return a cancelled task.',
    );
    const logs = runtimePayload(await expectToolSuccess(bridge, logsName, {
      limit: 20,
    }), logsName);
    requireCondition(
      Array.isArray(logs.logs)
        && logs.logs.some((item) => item?.task_id === task.task_id),
      'Runtime logs omitted the caller-owned task.',
    );
    return task;
  };

  const requestHandoff = async (ownerSessionId, sequence) => {
    const requestChallenge = Buffer.from(supervisionChallengeBuffer);
    const body = {
      challenge: requestChallenge.toString('utf8'),
      session_id: ownerSessionId,
      sequence,
    };
    requestChallenge.fill(0);
    return gatewayRequest(
      descriptor,
      '/v1/test/supervision-handoff',
      body,
    );
  };

  const compatibilityTool = async (bridge, route) => {
    const result = await bridge.callTool(route, {});
    const structured = unwrapToolResult(result, route);
    if (result.isError !== false || structured.ok !== true) {
      const publicCode = String(
        structured.error_code ?? structured.error?.code ?? 'unknown',
      ).toLowerCase().replaceAll(/[^a-z0-9]+/gu, '_');
      const publicDetail = `${
        structured.message ?? structured.error?.message ?? ''
      } ${structured.recovery ?? structured.error?.recovery ?? ''}`;
      const reason = publicDetail.includes('capture hub')
        ? 'capture_hub'
        : publicDetail.includes('safe supervision baseline')
          ? 'baseline_missing'
        : publicDetail.includes('not bound')
          ? 'not_bound'
        : publicDetail.includes('exact browser')
          ? 'exact_browser'
          : publicDetail.includes('exact supervision tab')
            ? 'exact_tab'
            : publicDetail.includes('owner')
              ? 'owner'
              : 'other';
      liveSmokeStage = `${liveSmokeStage}_${publicCode}_${reason}`;
      throw new Error(`${route} returned a typed failure.`);
    }
    assertCompatibilityHasNoDashboardAuthority(structured, route);
    return structured;
  };

  try {
    liveSmokeStage = 'owner_session';
    const ownerSessionId = await createRawSession(
      descriptor,
      'supervision owner seam',
    );
    sessionIds.push(ownerSessionId);
    liveSmokeStage = 'owner_tab_discovery';
    const ownerTabs = await eventually(async () => {
      const listedTabs = await gatewayAgentCommand(
        descriptor,
        ownerSessionId,
        'list_tabs',
      );
      const active = listedTabs.tabs?.find((tab) => tab?.active === true);
      if (!Number.isSafeInteger(active?.tab_id)
          || !Number.isSafeInteger(active?.window_id)
          || !hasSameOriginAndPath(active?.url, fixture)) {
        return false;
      }
      return active;
    });
    const supervisedTarget = {
      browser_session_id: ownerTabs.window_id,
      window_session_id: ownerTabs.window_id,
      tab_id: ownerTabs.tab_id,
    };
    liveSmokeStage = 'owner_tab_claim';
    const ownerClaim = await gatewayAgentCommand(
      descriptor,
      ownerSessionId,
      'activate_tab',
      supervisedTarget,
    );
    requireCondition(
      ownerClaim.target?.tab_id === ownerTabs.tab_id,
      'Raw resumable session did not claim the exact initial fixture tab.',
    );

    liveSmokeStage = 'owner_bridge_resume';
    primary = createBridge('primary smoke bridge', ownerSessionId);
    await primary.initialize();
    const listed = await primary.request('tools/list');
    assertCompatibilityInventory(listed.tools, expectedNames);

    liveSmokeStage = 'owner_bridge_inventory';
    const initial = await expectToolSuccess(primary, 'list_tabs', {});
    const initialActive = initial.tabs?.find((tab) => tab.active === true);
    requireCondition(
      initialActive?.tab_id === ownerTabs.tab_id
        && initialActive?.owned_by_session === true,
      'Resumed MCP consumer did not retain the exact initial owner binding.',
    );

    liveSmokeStage = 'supervision_page_read';
    const supervisedPage = await eventually(async () => {
      const result = await expectToolSuccess(primary, 'read_page', {
        tab_id: ownerTabs.tab_id,
        max_chars: 20_000,
        max_nodes: 1_000,
      });
      return result.page?.visible_text?.includes('Prometheus MCP fixture page text')
        ? result
        : false;
    });
    requireCondition(
      supervisedPage.page.visible_text.includes('Prometheus MCP Fixture'),
      'Initial supervised page omitted fixture title text.',
    );
    liveSmokeStage = 'supervision_dom_snapshot';
    const supervisedSnapshot = await expectToolSuccess(
      primary,
      'get_dom_snapshot',
      {
        tab_id: ownerTabs.tab_id,
        max_chars: 200_000,
        max_nodes: 1_000,
      },
    );
    let supervisedTargets = parseSnapshotTargets(supervisedSnapshot);

    liveSmokeStage = 'supervision_compatibility_start';
    const compatibilityStart = await compatibilityTool(
      primary,
      'start_supervision_session',
    );
    liveSmokeStage = 'supervision_compatibility_snapshot';
    const compatibilityBaseline = await compatibilityTool(
      primary,
      'get_supervision_snapshot',
    );
    liveSmokeStage = 'supervision_compatibility_shape';
    requireCondition(
      JSON.stringify(compatibilityStart).includes('"kind":"baseline"')
        && JSON.stringify(compatibilityBaseline).includes('"kind":"baseline"'),
      'MCP compatibility consumer did not attach to a real baseline stream.',
    );

    liveSmokeStage = 'supervision_handoff';
    const outOfOrder = await requestHandoff(ownerSessionId, 2);
    requireCondition(
      outOfOrder?.ok === false && outOfOrder.status === 'OUT_OF_ORDER',
      'Supervision handoff accepted sequence two before sequence one.',
    );
    const wrongChallengeBuffer = Buffer.alloc(64, 0x30);
    const wrongChallengeBody = {
      challenge: wrongChallengeBuffer.toString('utf8'),
      session_id: ownerSessionId,
      sequence: 1,
    };
    wrongChallengeBuffer.fill(0);
    const wrongChallenge = await gatewayRequest(
      descriptor,
      '/v1/test/supervision-handoff',
      wrongChallengeBody,
    );
    requireCondition(
      wrongChallenge?.ok === false && wrongChallenge.status === 'DENIED',
      'Supervision handoff did not reject a wrong challenge.',
    );

    const handoffA = await requestHandoff(ownerSessionId, 1);
    requireCondition(
      handoffA?.ok === true
        && handoffA.status === 'DELIVERED'
        && handoffA.sequence === 1
        && /^[A-Z0-9]{4}-[A-Z0-9]{4}$/u.test(handoffA.pairing_code),
      'Supervision handoff slot one was not delivered exactly once.',
    );
    pairingCodes.push(handoffA.pairing_code);
    const replayA = await requestHandoff(ownerSessionId, 1);
    requireCondition(
      replayA?.ok === false && replayA.status === 'OUT_OF_ORDER',
      'Supervision handoff replay was not denied.',
    );

    const redeemedA = await gatewaySupervision(descriptor, 'redeem', {
      pairing_code: handoffA.pairing_code,
      client_label: 'Phase 21 viewer A',
    });
    handoffA.pairing_code = '';
    const viewerA = dashboardAuthority(redeemedA, 'redeem').dashboard_session;
    dashboardSessions.push(viewerA);
    let baselineA = dashboardAuthority(
      await gatewaySupervision(descriptor, 'baseline', {
        dashboard_session: viewerA,
      }),
      'baseline',
    );
    await gatewaySupervision(descriptor, 'ack', {
      dashboard_session: viewerA,
      document_epoch: baselineA.document_epoch,
      sequence: baselineA.sequence,
    });

    liveSmokeStage = 'supervision_action_ordinary';
    const ordinaryAction = await gatewaySupervision(descriptor, 'action', {
      dashboard_session: viewerA,
      document_epoch: baselineA.document_epoch,
      sequence: baselineA.sequence,
      action: {
        category: 'click',
        ref: supervisedTargets.button.ref,
      },
    });
    liveSmokeStage = 'supervision_action_controller';
    requireCondition(
      ordinaryAction.result.snapshot?.target?.controller_label
        === 'Phase 21 viewer A',
      'The real Enable Control dialog did not grant viewer A sole control.',
    );
    liveSmokeStage = 'supervision_action_diff';
    const afterOrdinary = dashboardAuthority(
      await gatewaySupervision(descriptor, 'diff', {
        dashboard_session: viewerA,
        document_epoch: baselineA.document_epoch,
        after_sequence: baselineA.sequence,
      }),
      'diff',
    );
    await gatewaySupervision(descriptor, 'ack', {
      dashboard_session: viewerA,
      document_epoch: afterOrdinary.document_epoch,
      sequence: afterOrdinary.sequence,
    });

    liveSmokeStage = 'supervision_action_consequential';
    await gatewaySupervision(descriptor, 'action', {
      dashboard_session: viewerA,
      document_epoch: afterOrdinary.document_epoch,
      sequence: afterOrdinary.sequence,
      action: {
        category: 'navigate',
        navigation: `${fixtureUrl}#phase21-remote-action`,
      },
    });
    baselineA = afterOrdinary;
    liveSmokeStage = 'supervision_action_refresh_targets';
    supervisedTargets = parseSnapshotTargets(
      await expectToolSuccess(primary, 'get_dom_snapshot', {
        tab_id: ownerTabs.tab_id,
        max_chars: 200_000,
        max_nodes: 1_000,
      }),
    );

    liveSmokeStage = 'supervision_viewer_b_handoff';
    const handoffB = await requestHandoff(ownerSessionId, 2);
    supervisionChallengeBuffer.fill(0);
    requireCondition(
      handoffB?.ok === true
        && handoffB.status === 'DELIVERED'
        && handoffB.sequence === 2
        && /^[A-Z0-9]{4}-[A-Z0-9]{4}$/u.test(handoffB.pairing_code),
      'Supervision handoff slot two was not delivered after viewer A.',
    );
    pairingCodes.push(handoffB.pairing_code);
    liveSmokeStage = 'supervision_viewer_b_redeem';
    const redeemedB = await gatewaySupervision(descriptor, 'redeem', {
      pairing_code: handoffB.pairing_code,
      client_label: 'Phase 21 viewer B',
    });
    handoffB.pairing_code = '';
    const viewerB = dashboardAuthority(redeemedB, 'redeem').dashboard_session;
    dashboardSessions.push(viewerB);

    liveSmokeStage = 'supervision_viewer_b_baseline';
    let baselineB = dashboardAuthority(
      await gatewaySupervision(descriptor, 'baseline', {
        dashboard_session: viewerB,
      }),
      'baseline',
    );
    await gatewaySupervision(descriptor, 'ack', {
      dashboard_session: viewerB,
      document_epoch: baselineB.document_epoch,
      sequence: baselineB.sequence,
    });
    await gatewaySupervision(descriptor, 'action', {
      dashboard_session: viewerB,
      document_epoch: baselineB.document_epoch,
      sequence: baselineB.sequence,
      action: {
        category: 'scroll',
        delta_y: 120,
      },
    }, 'CONTROLLER_CONFLICT');

    liveSmokeStage = 'supervision_shared_mutation';
    const supervisedMutation = await expectToolSuccess(primary, 'click', {
      tab_id: ownerTabs.tab_id,
      ...supervisedTargets.button,
    });
    requireCondition(
      supervisedMutation.page?.verification_succeeded === true,
      'MCP consumer did not produce the shared real mutation.',
    );
    liveSmokeStage = 'supervision_shared_viewer_a_diff';
    const diffAResponse = await gatewaySupervision(descriptor, 'diff', {
      dashboard_session: viewerA,
      document_epoch: baselineA.document_epoch,
      after_sequence: baselineA.sequence,
    });
    liveSmokeStage = 'supervision_shared_viewer_b_diff';
    const diffBResponse = await gatewaySupervision(descriptor, 'diff', {
      dashboard_session: viewerB,
      document_epoch: baselineB.document_epoch,
      after_sequence: baselineB.sequence,
    });
    liveSmokeStage = 'supervision_shared_compatibility_diff';
    const compatibilityDiff = await compatibilityTool(
      primary,
      'get_supervision_diff',
    );
    const diffA = dashboardAuthority(diffAResponse, 'diff');
    const diffB = dashboardAuthority(diffBResponse, 'diff');
    requireCondition(
      JSON.stringify(compatibilityDiff).includes('"kind":"diff"'),
      'MCP compatibility cursor did not independently observe the mutation.',
    );
    await Promise.all([
      gatewaySupervision(descriptor, 'ack', {
        dashboard_session: viewerA,
        document_epoch: diffA.document_epoch,
        sequence: diffA.sequence,
      }),
      gatewaySupervision(descriptor, 'ack', {
        dashboard_session: viewerB,
        document_epoch: diffB.document_epoch,
        sequence: diffB.sequence,
      }),
    ]);

    liveSmokeStage = 'supervision_resync_gap_targets';
    supervisedTargets = parseSnapshotTargets(
      await expectToolSuccess(primary, 'get_dom_snapshot', {
        tab_id: ownerTabs.tab_id,
        max_chars: 200_000,
        max_nodes: 1_000,
      }),
    );
    for (let index = 0; index < 35; index += 1) {
      liveSmokeStage = `supervision_resync_gap_click_${index}`;
      const gapMutation = await expectToolSuccess(primary, 'click', {
        tab_id: ownerTabs.tab_id,
        ...supervisedTargets.button,
      });
      requireCondition(
        gapMutation.page?.verification_succeeded === true,
        'Gap mutation was not verified by the MCP consumer.',
      );
      liveSmokeStage = `supervision_resync_gap_compatibility_${index}`;
      const gapCompatibilityDiff = await compatibilityTool(
        primary,
        'get_supervision_diff',
      );
      requireCondition(
        JSON.stringify(gapCompatibilityDiff).includes('"kind":"diff"'),
        'Compatibility consumer did not observe the gap mutation.',
      );
      liveSmokeStage = `supervision_resync_gap_snapshot_${index}`;
      supervisedTargets = parseSnapshotTargets(
        await expectToolSuccess(primary, 'get_dom_snapshot', {
          tab_id: ownerTabs.tab_id,
          max_chars: 200_000,
          max_nodes: 1_000,
        }),
      );
    }
    liveSmokeStage = 'supervision_resync_viewer_a';
    await gatewaySupervision(descriptor, 'diff', {
      dashboard_session: viewerA,
      document_epoch: diffA.document_epoch,
      after_sequence: diffA.sequence,
    }, 'RESYNC_REQUIRED');
    liveSmokeStage = 'supervision_resync_viewer_b';
    await gatewaySupervision(descriptor, 'diff', {
      dashboard_session: viewerB,
      document_epoch: diffB.document_epoch,
      after_sequence: diffB.sequence,
    }, 'RESYNC_REQUIRED');
    liveSmokeStage = 'supervision_resync_baselines';
    const [resyncBaselineA, resyncBaselineB] = await Promise.all([
      gatewaySupervision(descriptor, 'baseline', {
        dashboard_session: viewerA,
      }),
      gatewaySupervision(descriptor, 'baseline', {
        dashboard_session: viewerB,
      }),
    ]);
    baselineA = dashboardAuthority(resyncBaselineA, 'baseline');
    baselineB = dashboardAuthority(resyncBaselineB, 'baseline');
    const resyncSessions = resyncBaselineA.result.snapshot?.sessions ?? [];
    const resyncViewerA = resyncSessions.find(
      (session) => session?.client?.display_label === 'Phase 21 viewer A',
    );
    const resyncViewerB = resyncSessions.find(
      (session) => session?.client?.display_label === 'Phase 21 viewer B',
    );
    requireCondition(
      resyncViewerA?.client?.expires_at_ms > Date.now() + 60_000
        && resyncViewerB?.client?.expires_at_ms > Date.now() + 60_000,
      'Dashboard viewer TTL became unexpectedly short during gap recovery.',
    );
    requireCondition(
      baselineA.document_epoch === baselineB.document_epoch
        && baselineA.document_epoch === diffA.document_epoch
        && baselineA.sequence === baselineB.sequence
        && baselineA.sequence > diffA.sequence,
      'Retention gap did not force both viewers onto one fresh shared baseline.',
    );
    liveSmokeStage = 'supervision_resync_end';
    const ended = await Promise.all([
      endDashboardSession(descriptor, viewerB),
      endDashboardSession(descriptor, viewerA),
    ]);
    requireCondition(
      ended.some(Boolean),
      'Neither dashboard session completed an explicit terminal end.',
    );
    await compatibilityTool(primary, 'get_supervision_snapshot');
    await gatewaySupervision(descriptor, 'heartbeat', {
      dashboard_session: viewerA,
    }, 'UNAVAILABLE');
    await compatibilityTool(primary, 'end_supervision_session');

    liveSmokeStage = 'phase20_regression';
    // Bind both independent callers while the freshly launched regular
    // browser and its initial tab are known to be active.
    second = createBridge('second smoke bridge');
    await second.initialize();

    const opened = await expectToolSuccess(primary, 'new_tab', {
      url: fixtureUrl,
      foreground: false,
      visual_reason: visualReason,
      client: 'Codex',
    });
    const ownedTabId = opened.target?.tab_id;
    requireCondition(Number.isSafeInteger(ownedTabId), 'Background tab did not return a stable handle.');
    const afterOpen = await expectToolSuccess(primary, 'list_tabs', {});
    requireCondition(
      afterOpen.tabs.find((tab) => tab.active === true)?.tab_id === initialActive.tab_id,
      'Background open stole active-tab focus.',
    );
    const openedMetadata = afterOpen.tabs.find((tab) => tab.tab_id === ownedTabId);
    requireCondition(openedMetadata?.active === false && openedMetadata.owned_by_session === true, 'Background tab metadata is inconsistent.');

    await expectToolSuccess(primary, 'switch_tab', { tab_id: ownedTabId });
    await eventually(async () => {
      const tabs = await expectToolSuccess(primary, 'list_tabs', {});
      const currentUrl = tabs.tabs?.find((tab) => tab.tab_id === ownedTabId)?.url;
      return hasSameOriginAndPath(currentUrl, fixture);
    });
    const page = await eventually(async () => {
      const result = await expectToolSuccess(primary, 'read_page', {
        tab_id: ownedTabId,
        max_chars: 20_000,
        max_nodes: 1_000,
      });
      return result.page?.visible_text?.includes('Prometheus MCP fixture page text') ? result : false;
    });
    requireCondition(page.page.visible_text.includes('Prometheus MCP Fixture'), 'Page read omitted fixture title text.');

    const snapshot = await expectToolSuccess(primary, 'get_dom_snapshot', {
      tab_id: ownedTabId,
      max_chars: 200_000,
      max_nodes: 1_000,
    });
    const targets = parseSnapshotTargets(snapshot);

    const text = await expectToolSuccess(primary, 'get_text', {
      tab_id: ownedTabId,
      ...targets.text,
    });
    requireCondition(text.element_read?.value === 'Prometheus MCP fixture page text', 'Element text read changed fixture text.');
    const presentEmpty = await expectToolSuccess(primary, 'get_attribute', {
      tab_id: ownedTabId,
      ...targets.attribute,
      attribute: 'data-empty',
    });
    requireCondition(
      presentEmpty.element_read?.attribute_present === true
        && presentEmpty.element_read?.value === '',
      'Present-empty attribute lost presence semantics.',
    );
    const missing = await expectToolSuccess(primary, 'get_attribute', {
      tab_id: ownedTabId,
      ...targets.attribute,
      attribute: 'data-missing',
    });
    requireCondition(
      missing.element_read?.attribute_present === false
        && missing.element_read?.value === '',
      'Missing attribute did not remain distinct from present-empty.',
    );

    const typed = await expectToolSuccess(primary, 'type', {
      tab_id: ownedTabId,
      ...targets.input,
      text: typedText,
    });
    requireCondition(typed.page?.verification_succeeded === true, 'Type action was not mutation-verified.');
    const cleared = await expectToolSuccess(primary, 'clear_input', {
      tab_id: ownedTabId,
      ...targets.input,
    });
    requireCondition(
      cleared.page?.verification_succeeded === true
        && cleared.changed_state?.includes('input_cleared'),
      'clear_input did not route to the verified native clear action.',
    );
    const clicked = await expectToolSuccess(primary, 'click', {
      tab_id: ownedTabId,
      ...targets.button,
    });
    requireCondition(clicked.page?.verification_succeeded === true, 'Click action was not mutation-verified.');
    const mutation = await eventually(async () => {
      const result = await expectToolSuccess(primary, 'get_text', {
        tab_id: ownedTabId,
        ...targets.status,
      });
      return result.element_read?.value === 'clicked' ? result : false;
    });
    requireCondition(mutation.element_read.value === 'clicked', 'Fixture click mutation was not observable.');

    const coordinate = await expectToolFailure(primary, 'click_at', { x: 10, y: 10 });
    requireCondition(
      coordinate.error?.code === 'UNSUPPORTED_ROUTE'
        && coordinate.error?.replacements?.includes('click'),
      'Coordinate tool did not return typed unsupported guidance.',
    );
    const removed = await expectToolFailure(primary, 'start_visual_session', {});
    assertRemovedToolResult(removed);

    const listedProviders = runtimePayload(await expectToolSuccess(
      primary,
      'list_providers',
      { include_disabled: true },
    ), 'list_providers');
    const fixtureProvider = listedProviders.providers?.find(
      (provider) => provider?.provider_id === PHASE20_PROVIDER_ID,
    );
    requireCondition(
      isRecord(fixtureProvider)
        && fixtureProvider.kind === 'lm_studio'
        && fixtureProvider.route_class === 'local'
        && fixtureProvider.model_id === PHASE20_MODEL_ID
        && fixtureProvider.canonical_endpoint === `${fixture.origin}/v1/`
        && fixtureProvider.enabled === true
        && fixtureProvider.secret_configured === false,
      'Runtime test bootstrap provider metadata is unavailable or malformed.',
    );
    const providerConfig = runtimePayload(await expectToolSuccess(
      primary,
      'get_provider_config',
      { provider_id: PHASE20_PROVIDER_ID },
    ), 'get_provider_config');
    requireCondition(
      providerConfig.provider?.provider_id === PHASE20_PROVIDER_ID,
      'Read-only provider configuration did not return the fixture provider.',
    );
    const discovery = await discoverModelsThroughStatus(
      primary,
      PHASE20_PROVIDER_ID,
    );
    requireCondition(
      Array.isArray(discovery.models)
        && discovery.pending === false
        && discovery.models.length === 1
        && discovery.models[0] === PHASE20_MODEL_ID,
      'Read-only model discovery returned an invalid fixture result.',
    );

    const providerSnapshotBeforeDenial = JSON.stringify(listedProviders.providers);
    const normalProviderDenial = await expectToolFailure(
      primary,
      'set_provider_config',
      { provider_id: PHASE20_PROVIDER_ID, enabled: false },
    );
    const secretProviderDenial = await expectToolFailure(
      primary,
      'set_provider_config',
      { provider_id: PHASE20_PROVIDER_ID, nested: [{ api_key: providerSecretSentinel }] },
    );
    requireCondition(
      normalProviderDenial.error?.code === 'LOCAL_UI_REQUIRED'
        && JSON.stringify(normalProviderDenial) === JSON.stringify(secretProviderDenial)
        && !JSON.stringify(secretProviderDenial).includes(providerSecretSentinel),
      'External provider mutation denial was not stable and content-free.',
    );
    const providersAfterDenial = runtimePayload(await expectToolSuccess(
      primary,
      'list_providers',
      { include_disabled: true },
    ), 'list_providers');
    requireCondition(
      JSON.stringify(providersAfterDenial.providers) === providerSnapshotBeforeDenial,
      'External provider mutation changed the native registry snapshot.',
    );

    const memory = runtimePayload(await expectToolSuccess(primary, 'save_memory', {
      title: 'Phase 20 caller-owned memory',
      text: 'Remember the bounded fixture workflow.',
      tags: ['phase20', 'smoke'],
      shared: false,
    }), 'save_memory').memory;
    requireCondition(
      typeof memory?.memory_id === 'string'
        && memory.owned_by_caller === true
        && memory.visibility === 'caller_owned',
      'Caller-owned memory was not saved safely.',
    );
    const memories = runtimePayload(await expectToolSuccess(
      primary,
      'list_memory',
      { limit: 20 },
    ), 'list_memory');
    requireCondition(
      memories.memories?.some((item) => item?.memory_id === memory.memory_id),
      'Caller-owned memory was absent from its owner list.',
    );
    const searchedMemory = runtimePayload(await expectToolSuccess(
      primary,
      'search_memory',
      { query: 'fixture', limit: 20 },
    ), 'search_memory');
    requireCondition(
      searchedMemory.memories?.some((item) => item?.memory_id === memory.memory_id),
      'Caller-owned memory search did not find its bounded fixture record.',
    );
    const memoryStats = runtimePayload(await expectToolSuccess(
      primary,
      'get_memory_stats',
      {},
    ), 'get_memory_stats');
    requireCondition(
      Number.isSafeInteger(memoryStats.count)
        && memoryStats.count >= 1
        && Number.isSafeInteger(memoryStats.total_bytes)
        && memoryStats.total_bytes > 0,
      'Caller-owned memory statistics were not live.',
    );

    const guide = runtimePayload(await expectToolSuccess(primary, 'save_site_guide', {
      title: 'Phase 20 fixture guide',
      instructions: 'Use only the bounded fixture page.',
      canonical_origin: fixture.origin,
      tags: ['phase20'],
      shared: false,
    }), 'save_site_guide').guide;
    requireCondition(
      typeof guide?.guide_id === 'string'
        && guide.canonical_origin === fixture.origin
        && guide.owned_by_caller === true,
      'Caller-owned site guide was not saved with its exact origin.',
    );
    const guides = runtimePayload(await expectToolSuccess(
      primary,
      'list_site_guides',
      { limit: 20 },
    ), 'list_site_guides');
    requireCondition(
      guides.guides?.some((item) => item?.guide_id === guide.guide_id),
      'Caller-owned site guide was absent from its owner list.',
    );
    const guideDetail = runtimePayload(await expectToolSuccess(
      primary,
      'get_site_guide',
      { guide_id: guide.guide_id },
    ), 'get_site_guide');
    requireCondition(
      guideDetail.guide?.guide_id === guide.guide_id,
      'Caller-owned site guide detail did not round-trip.',
    );

    const vaultEntry = runtimePayload(await expectToolSuccess(
      primary,
      'create_vault_entry',
      {
        label: 'Phase 20 fixture login',
        kind: 'credential',
        canonical_site_origin: 'https://example.test',
      },
    ), 'create_vault_entry').entry;
    requireCondition(
      typeof vaultEntry?.id === 'string'
        && vaultEntry.kind === 'credential'
        && vaultEntry.secret_configured === false,
      'Vault metadata creation exposed or fabricated a configured secret.',
    );
    const vaultEntries = runtimePayload(await expectToolSuccess(
      primary,
      'list_vault_entries',
      { kind: 'credential' },
    ), 'list_vault_entries');
    requireCondition(
      vaultEntries.entries?.some((entry) => entry?.id === vaultEntry.id),
      'Vault metadata did not remain listable.',
    );
    const vaultUse = runtimePayload(await expectToolSuccess(
      primary,
      'vault_autofill',
      { entry_id: vaultEntry.id },
    ), 'vault_autofill');
    requireCondition(
      vaultUse.status === 'VAULT_NATIVE_CONFIRMATION_UNAVAILABLE',
      'Vault use did not return native-confirmation-only status.',
    );

    const primaryTask = await submitStatusCancel(
      primary,
      primaryPromptSentinel,
    );
    requireCondition(primaryTask.safe_title.includes('[redacted]'), 'Runtime safe title did not redact prompt metadata.');

    const diagnostics = await expectToolSuccess(primary, 'diagnostics', {});
    assertDiagnosticInventory(diagnostics);
    for (const key of ['vault', 'provider']) {
      requireCondition(
        diagnostics.components.find((component) => component.key === key)?.status === 'ready',
        `${key} diagnostics did not report live Phase 20 state.`,
      );
    }
    const runtimeDiagnostics = runtimePayload(await expectToolSuccess(
      primary,
      'runtime_diagnostics',
      {},
    ), 'runtime_diagnostics');
    requireCondition(
      runtimeDiagnostics.components?.some(
        (component) => component?.key === 'provider' && component.status === 'ready',
      )
        && runtimeDiagnostics.components?.some(
          (component) => component?.key === 'vault' && component.status === 'ready',
        ),
      'Native runtime diagnostics did not preserve live provider and vault state.',
    );

    const secondProviders = runtimePayload(await expectToolSuccess(
      second,
      'list_providers',
      { include_disabled: true },
    ), 'list_providers');
    requireCondition(
      secondProviders.providers?.some(
        (provider) => provider?.provider_id === PHASE20_PROVIDER_ID,
      ),
      'Second external client could not read the bootstrap provider.',
    );
    const secondDiscovery = await discoverModelsThroughStatus(
      second,
      PHASE20_PROVIDER_ID,
    );
    requireCondition(
      Array.isArray(secondDiscovery.models)
        && secondDiscovery.pending === false
        && secondDiscovery.models.includes(PHASE20_MODEL_ID),
      'Second external client could not use read-only model discovery.',
    );
    const secondMemories = runtimePayload(await expectToolSuccess(
      second,
      'list_memory',
      { limit: 20 },
    ), 'list_memory');
    const secondGuides = runtimePayload(await expectToolSuccess(
      second,
      'list_site_guides',
      { limit: 20 },
    ), 'list_site_guides');
    const secondTasksBefore = runtimePayload(await expectToolSuccess(
      second,
      'list_tasks',
      { limit: 20 },
    ), 'list_tasks');
    requireCondition(
      secondMemories.memories?.every((item) => item?.memory_id !== memory.memory_id)
        && secondGuides.guides?.every((item) => item?.guide_id !== guide.guide_id)
        && secondTasksBefore.tasks?.every((item) => item?.task_id !== primaryTask.task_id),
      'Second external client observed another caller\'s runtime state.',
    );
    await submitStatusCancel(second, secondPromptSentinel, true);
    const secondDiagnostics = await expectToolSuccess(second, 'diagnostics', {});
    assertDiagnosticInventory(secondDiagnostics);
    const denied = await expectToolFailure(second, 'navigate', {
      tab_id: ownedTabId,
      url: fixtureUrl,
    });
    requireCondition(denied.error_code === 'TAB_NOT_OWNED', 'Second session controlled another session\'s tab.');

    const resumeId = await createRawSession(descriptor, 'resume smoke seam');
    sessionIds.push(resumeId);
    const firstResume = createBridge('first resume bridge', resumeId);
    await firstResume.initialize();
    const resumeOpen = await expectToolSuccess(firstResume, 'new_tab', {
      url: fixtureUrl,
      foreground: false,
    });
    const resumeTabId = resumeOpen.target?.tab_id;
    requireCondition(Number.isSafeInteger(resumeTabId), 'Resume seam did not own a stable tab.');
    await firstResume.close({ graceful: false });
    const freshDenied = await expectToolFailure(second, 'navigate', {
      tab_id: resumeTabId,
      url: `${fixtureUrl}#fresh-session-denied`,
    });
    requireCondition(
      freshDenied.error_code === 'TAB_NOT_OWNED',
      'A fresh bridge inherited authority from the disconnected resume seam.',
    );
    const resumed = createBridge('resumed smoke bridge', resumeId);
    await resumed.initialize();
    const resumedNavigation = await expectToolSuccess(resumed, 'navigate', {
      tab_id: resumeTabId,
      url: `${fixtureUrl}#resumed-authority`,
    });
    requireCondition(
      resumedNavigation.target?.tab_id === resumeTabId,
      'Resumed bridge did not retain the original session authority.',
    );
    await resumed.close({ graceful: true });

    const expiryId = await createRawSession(descriptor, 'expiry smoke seam');
    sessionIds.push(expiryId);
    const expiring = createBridge('expiring smoke bridge', expiryId);
    await expiring.initialize();
    const expiryOpen = await expectToolSuccess(expiring, 'new_tab', {
      url: fixtureUrl,
      foreground: false,
    });
    const expiryTabId = expiryOpen.target?.tab_id;
    requireCondition(Number.isSafeInteger(expiryTabId), 'Expiry session did not own a stable tab.');
    await expiring.close({ graceful: false });
    await new Promise((resolve) => setTimeout(resolve, expiryWait));
    const expiredResume = createBridge('expired resume bridge', expiryId);
    let expiredResumeDenied = false;
    try {
      await expiredResume.initialize();
    } catch {
      expiredResumeDenied = true;
    }
    requireCondition(expiredResumeDenied, 'Expired opaque session unexpectedly resumed.');
    await expiredResume.close({ graceful: false });
    const reclaimedExpired = await expectToolSuccess(second, 'navigate', {
      tab_id: expiryTabId,
      url: fixtureUrl,
    });
    requireCondition(reclaimedExpired.target?.tab_id === expiryTabId, 'Expired ownership was not released.');

    const localUiCompatibility = await compatibilityTool(
      primary,
      'create_supervision_pairing',
    );
    requireCondition(
      JSON.stringify(localUiCompatibility).includes('"kind":"local_ui"'),
      'Pairing compatibility route did not remain local-UI-only.',
    );
    await primary.close({ graceful: true });
    const reclaimedClosed = await expectToolSuccess(second, 'navigate', {
      tab_id: ownedTabId,
      url: fixtureUrl,
    });
    requireCondition(reclaimedClosed.target?.tab_id === ownedTabId, 'Graceful close did not release ownership.');
    await second.close({ graceful: true });

    liveSmokeStage = 'privacy_scan';
    const privateValues = [
      descriptor.bearer,
      descriptor.instance_nonce,
      supervisionChallengeSentinel,
      ...sessionIds,
      ...pairingCodes,
      ...dashboardSessions,
      visualReason,
      typedText,
      primaryPromptSentinel,
      secondPromptSentinel,
      providerSecretSentinel,
      profilePath,
    ];
    const allowedToolResultValues = [
      'Prometheus MCP fixture page text',
      'Prometheus MCP same-origin child text',
    ];
    for (const bridge of bridges) {
      bridge.assertProtocolSafety(privateValues, allowedToolResultValues);
      assertSafeCapturedOutput(
        bridge.capturedOutput,
        [...privateValues, ...allowedToolResultValues],
      );
    }
    await writePrivateDenylist(
      denylistFile,
      [...privateValues, ...allowedToolResultValues],
    );
    return {
      ok: true,
      tools: listed.tools.length,
      diagnostics: diagnostics.components.length,
      runtime_flows: true,
      caller_isolation: true,
      provider_bootstrap: true,
      provider_mutation_denied: true,
      vault_confirmation_only: true,
      background_focus_preserved: true,
      ownership_denied: true,
      resume_proven: true,
      expiry_released: true,
      close_released: true,
      supervision_two_viewers: true,
      supervision_shared_hub: true,
      supervision_actions: true,
      supervision_resync: true,
      supervision_cleanup: true,
      supervision_compatibility_private: true,
      children_closed: bridges.length,
    };
  } finally {
    for (const bridge of bridges.reverse()) {
      await bridge.close({ graceful: false }).catch(() => {});
    }
  }
};

const isMain = process.argv[1]
  && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href;

if (isMain) {
  try {
    const result = await runLiveSmoke();
    process.stdout.write(`${JSON.stringify(result)}\n`);
  } catch {
    process.stderr.write(
      `prometheus-mcp smoke client: live smoke failed at ${liveSmokeStage}\n`,
    );
    process.exitCode = 1;
  }
}
