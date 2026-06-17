#!/usr/bin/env node

import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const serverPath = join(here, "server.mjs");
const agentUrl = process.env.PROMETHEUS_AGENT_URL || "http://127.0.0.1:17880";
const server = spawn(process.execPath, [serverPath], {
  env: { ...process.env, PROMETHEUS_AGENT_URL: agentUrl },
  stdio: ["pipe", "pipe", "inherit"]
});

let buffer = Buffer.alloc(0);
let nextId = 1;
const pending = new Map();

server.stdout.on("data", (chunk) => {
  buffer = Buffer.concat([buffer, chunk]);
  while (true) {
    const headerEnd = buffer.indexOf("\r\n\r\n");
    if (headerEnd < 0) return;
    const header = buffer.subarray(0, headerEnd).toString("utf8");
    const match = header.match(/content-length:\s*(\d+)/i);
    if (!match) throw new Error(`Missing content-length: ${header}`);
    const length = Number(match[1]);
    const bodyStart = headerEnd + 4;
    if (buffer.length < bodyStart + length) return;
    const body = buffer.subarray(bodyStart, bodyStart + length).toString("utf8");
    buffer = buffer.subarray(bodyStart + length);
    const message = JSON.parse(body);
    const entry = pending.get(message.id);
    if (entry) {
      pending.delete(message.id);
      entry.resolve(message);
    }
  }
});

function send(method, params = {}) {
  const id = nextId++;
  const payload = Buffer.from(JSON.stringify({ jsonrpc: "2.0", id, method, params }), "utf8");
  server.stdin.write(`Content-Length: ${payload.length}\r\n\r\n`);
  server.stdin.write(payload);
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject });
    setTimeout(() => {
      if (pending.delete(id)) reject(new Error(`Timed out waiting for ${method}`));
    }, 5000);
  });
}

async function callTool(name, args = {}) {
  const response = await send("tools/call", { name, arguments: args });
  if (response.error) throw new Error(JSON.stringify(response.error));
  const text = response.result.content[0].text;
  return JSON.parse(text);
}

try {
  await send("initialize", {
    protocolVersion: "2024-11-05",
    capabilities: {},
    clientInfo: { name: "prometheus-smoke", version: "0.1.0" }
  });
  const list = await send("tools/list");
  const names = new Set(list.result.tools.map((tool) => tool.name));
  for (const required of ["list_tabs", "new_tab", "type", "get_attribute", "diagnostics", "submit_task", "get_provider_config", "start_supervision_session"]) {
    if (!names.has(required)) throw new Error(`missing MCP tool ${required}`);
  }

  const page = "data:text/html,<title>MCP Smoke</title><main><h1>MCP Smoke</h1><input id=name></main>";
  const created = await callTool("new_tab", { client: "mcp-smoke", visual_reason: "Open MCP smoke page", url: page });
  if (!created.ok) throw new Error(JSON.stringify(created));
  const tabIndex = created.result.tabIndex;

  await callTool("wait_for_load", { client: "mcp-smoke", tabIndex, timeoutMs: 3000 });
  await callTool("type", { client: "mcp-smoke", tabIndex, selector: "#name", text: "Prometheus", visual_reason: "Type into smoke input" });
  const value = await callTool("get_attribute", { tabIndex, selector: "#name", attribute: "value" });
  if (value.result.attribute.value !== "Prometheus") {
    throw new Error(`unexpected input value: ${JSON.stringify(value)}`);
  }

  const diagnostics = await callTool("diagnostics", {});
  if (!diagnostics.result.server.listening) {
    throw new Error(`diagnostics server not listening: ${JSON.stringify(diagnostics)}`);
  }
  if (!diagnostics.result.runtime || diagnostics.result.adapters.runtime !== true) {
    throw new Error(`runtime diagnostics missing: ${JSON.stringify(diagnostics)}`);
  }

  const task = await callTool("submit_task", { client: "mcp-smoke", tabIndex, prompt: "Summarize the current MCP smoke page" });
  if (!task.ok || task.result.task.status !== "complete") {
    throw new Error(`submit_task did not complete: ${JSON.stringify(task)}`);
  }

  const providers = await callTool("get_provider_config", {});
  if (!providers.ok || !Array.isArray(providers.result.providers) || providers.result.providers.length < 4) {
    throw new Error(`provider config missing expected providers: ${JSON.stringify(providers)}`);
  }

  const legacy = await callTool("start_visual_session", {});
  if (legacy.ok !== false || legacy.error.code !== "legacy_visual_session_removed") {
    throw new Error(`legacy visual session did not return migration error: ${JSON.stringify(legacy)}`);
  }

  await callTool("close_tab", { client: "mcp-smoke", tabIndex, visual_reason: "Close MCP smoke tab", is_final: true });
  console.log("MCP bridge smoke completed");
} finally {
  server.kill();
}
