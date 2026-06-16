#!/usr/bin/env node

const agentUrl = process.env.PROMETHEUS_AGENT_URL || "http://127.0.0.1:17880";
let agentToken = process.env.PROMETHEUS_AGENT_TOKEN || "";

const tools = [
  "list_tabs",
  "new_tab",
  "switch_tab",
  "navigate",
  "reload",
  "close_tab",
  "read_page",
  "get_text",
  "get_attribute",
  "get_dom_snapshot",
  "get_page_snapshot",
  "execute_js",
  "click",
  "type",
  "press_key",
  "scroll",
  "hover",
  "select",
  "clear",
  "drag_drop",
  "wait_for_load",
  "diagnostics",
  "open_internal_surface",
  "submit_task",
  "cancel_task",
  "task_status",
  "list_tasks",
  "get_provider_config",
  "list_providers",
  "discover_models",
  "set_provider_config",
  "list_runtime_logs",
  "action_history",
  "runtime_diagnostics",
  "save_memory",
  "list_memory",
  "save_site_guide",
  "list_site_guides",
  "create_vault_entry",
  "list_vault_entries",
  "vault_autofill",
  "create_supervision_pairing",
  "start_supervision_session",
  "get_supervision_snapshot",
  "get_supervision_diff",
  "end_supervision_session"
].map((name) => ({
  name,
  description: `Prometheus native browser tool: ${name}`,
  inputSchema: {
    type: "object",
    additionalProperties: true,
    properties: {
      client: { type: "string" },
      visual_reason: { type: "string" },
      is_final: { type: "boolean" }
    }
  }
}));

let buffer = Buffer.alloc(0);

process.stdin.on("data", (chunk) => {
  buffer = Buffer.concat([buffer, chunk]);
  processMessages().catch((error) => {
    writeResponse(null, {
      jsonrpc: "2.0",
      error: { code: -32603, message: error.message || String(error) }
    });
  });
});

async function processMessages() {
  while (true) {
    const headerEnd = buffer.indexOf("\r\n\r\n");
    if (headerEnd < 0) return;

    const header = buffer.subarray(0, headerEnd).toString("utf8");
    const match = header.match(/content-length:\s*(\d+)/i);
    if (!match) {
      buffer = buffer.subarray(headerEnd + 4);
      continue;
    }

    const length = Number(match[1]);
    const bodyStart = headerEnd + 4;
    if (buffer.length < bodyStart + length) return;

    const body = buffer.subarray(bodyStart, bodyStart + length).toString("utf8");
    buffer = buffer.subarray(bodyStart + length);
    await handleMessage(JSON.parse(body));
  }
}

async function handleMessage(message) {
  if (!("id" in message)) {
    return;
  }

  try {
    if (message.method === "initialize") {
      writeResponse(message.id, {
        jsonrpc: "2.0",
        id: message.id,
        result: {
          protocolVersion: "2024-11-05",
          capabilities: { tools: {} },
          serverInfo: { name: "prometheus", version: "0.1.0" }
        }
      });
      return;
    }

    if (message.method === "ping") {
      writeResponse(message.id, { jsonrpc: "2.0", id: message.id, result: {} });
      return;
    }

    if (message.method === "tools/list") {
      writeResponse(message.id, { jsonrpc: "2.0", id: message.id, result: { tools } });
      return;
    }

    if (message.method === "tools/call") {
      const name = message.params?.name;
      const args = message.params?.arguments || {};
      const result = await callPrometheus(name, args, message.id);
      writeResponse(message.id, {
        jsonrpc: "2.0",
        id: message.id,
        result: {
          isError: result.ok !== true,
          content: [{ type: "text", text: JSON.stringify(result) }]
        }
      });
      return;
    }

    writeResponse(message.id, {
      jsonrpc: "2.0",
      id: message.id,
      error: { code: -32601, message: `Unknown method: ${message.method}` }
    });
  } catch (error) {
    writeResponse(message.id, {
      jsonrpc: "2.0",
      id: message.id,
      error: { code: -32603, message: error.message || String(error) }
    });
  }
}

async function callPrometheus(tool, params, id) {
  const token = await authorizationToken();
  const response = await fetch(`${agentUrl}/agent/command`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
    body: JSON.stringify({ id: String(id), tool, params })
  });

  if (!response.ok) {
    return {
      ok: false,
      error: { code: "bridge_http_error", message: `Prometheus native server returned HTTP ${response.status}` }
    };
  }

  return response.json();
}

async function authorizationToken() {
  if (agentToken) {
    return agentToken;
  }

  const response = await fetch(`${agentUrl}/health`, {
    headers: { accept: "application/json" }
  });
  if (!response.ok) {
    throw new Error(`Prometheus native server health returned HTTP ${response.status}`);
  }

  const health = await response.json();
  agentToken = health.authorization?.token || "";
  if (!agentToken) {
    throw new Error("Prometheus native server health did not include an authorization token");
  }
  return agentToken;
}

function writeResponse(id, payload) {
  const body = Buffer.from(JSON.stringify(payload), "utf8");
  process.stdout.write(`Content-Length: ${body.length}\r\n\r\n`);
  process.stdout.write(body);
}
