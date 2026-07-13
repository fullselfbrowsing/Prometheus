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
const LATER_DIAGNOSTICS = new Set(['vault', 'provider', 'supervision', 'extensions']);

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
      await waitForExit(this.#child, 5_000);
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
  })) {
    requireCondition(typeof value === 'string' && value.length > 0, `${name} is required.`);
  }
  requireCondition(path.isAbsolute(descriptorPath), 'Descriptor path must be absolute.');
  requireCondition(path.isAbsolute(captureDirectory), 'Capture directory must be absolute.');
  requireCondition(path.isAbsolute(denylistFile), 'Denylist file must be absolute.');
  requireCondition(path.isAbsolute(profilePath), 'Profile path must be absolute.');
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
  const sessionIds = [];
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

  try {
    primary = createBridge('primary smoke bridge');
    await primary.initialize();
    const listed = await primary.request('tools/list');
    assertCompatibilityInventory(listed.tools, expectedNames);

    const initial = await expectToolSuccess(primary, 'list_tabs', {});
    const initialActive = initial.tabs?.find((tab) => tab.active === true);
    requireCondition(Number.isSafeInteger(initialActive?.tab_id), 'Initial active tab handle is unavailable.');

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
    const later = await expectToolFailure(primary, 'run_task', {});
    requireCondition(
      later.error?.code === 'NOT_READY' && later.error?.owner_phase === 20,
      'Phase 20 tool did not return its truthful owner.',
    );
    const removed = await expectToolFailure(primary, 'start_visual_session', {});
    assertRemovedToolResult(removed);

    const diagnostics = await expectToolSuccess(primary, 'diagnostics', {});
    assertDiagnosticInventory(diagnostics);

    second = createBridge('second smoke bridge');
    await second.initialize();
    const denied = await expectToolFailure(second, 'navigate', {
      tab_id: ownedTabId,
      url: fixtureUrl,
    });
    requireCondition(denied.error_code === 'TAB_NOT_OWNED', 'Second session controlled another session\'s tab.');

    const resumeId = await createRawSession(descriptor, 'resume smoke seam');
    sessionIds.push(resumeId);
    const firstResume = createBridge('first resume bridge', resumeId);
    await firstResume.initialize();
    await expectToolSuccess(firstResume, 'list_tabs', {});
    await firstResume.close({ graceful: false });
    const resumed = createBridge('resumed smoke bridge', resumeId);
    await resumed.initialize();
    await expectToolSuccess(resumed, 'list_tabs', {});
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
    const reclaimedExpired = await expectToolSuccess(second, 'navigate', {
      tab_id: expiryTabId,
      url: fixtureUrl,
    });
    requireCondition(reclaimedExpired.target?.tab_id === expiryTabId, 'Expired ownership was not released.');

    await primary.close({ graceful: true });
    const reclaimedClosed = await expectToolSuccess(second, 'navigate', {
      tab_id: ownedTabId,
      url: fixtureUrl,
    });
    requireCondition(reclaimedClosed.target?.tab_id === ownedTabId, 'Graceful close did not release ownership.');
    await second.close({ graceful: true });

    const deniedValues = [
      descriptor.bearer,
      descriptor.instance_nonce,
      ...sessionIds,
      'Prometheus MCP fixture page text',
      'Prometheus MCP same-origin child text',
      visualReason,
      typedText,
      profilePath,
    ];
    for (const bridge of bridges) {
      assertSafeCapturedOutput(bridge.capturedOutput, deniedValues);
    }
    await writePrivateDenylist(denylistFile, deniedValues);
    return {
      ok: true,
      tools: listed.tools.length,
      diagnostics: diagnostics.components.length,
      background_focus_preserved: true,
      ownership_denied: true,
      resume_proven: true,
      expiry_released: true,
      close_released: true,
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
    process.stderr.write('prometheus-mcp smoke client: live smoke failed\n');
    process.exitCode = 1;
  }
}
