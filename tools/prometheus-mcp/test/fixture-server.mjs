#!/usr/bin/env node

import { open } from 'node:fs/promises';
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export const FIXTURE_PAGE_TEXT = 'Prometheus MCP fixture page text';
export const FIXTURE_CHILD_TEXT = 'Prometheus MCP same-origin child text';
export const FIXTURE_MODEL_ID = 'phase20-fixture-model';
export const FIXTURE_PROVIDER_TEXT = 'Phase 20 fixture provider result';
export const FIXTURE_PROVIDER_TOOL = 'read_page';
export const MAX_FIXTURE_PROVIDER_REQUEST_BYTES = 128 * 1024;

const PAGE = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Prometheus MCP Fixture</title>
</head>
<body>
  <main>
    <h1>Prometheus MCP Fixture</h1>
    <p id="fixture-text" aria-label="fixture text target">${FIXTURE_PAGE_TEXT}</p>
    <p id="present-empty" data-empty="" aria-label="attribute fixture target">attribute fixture</p>
    <label for="fixture-input">Fixture input</label>
    <input id="fixture-input" aria-label="fixture input target" value="">
    <button id="fixture-button" type="button" aria-label="mutation button target">Apply mutation</button>
    <output id="mutation-status" aria-label="mutation status target">idle</output>
    <iframe id="fixture-frame" title="same-origin fixture" src="/child"></iframe>
  </main>
  <script>
    document.querySelector('#fixture-button').addEventListener('click', () => {
      document.querySelector('#mutation-status').textContent = 'clicked';
      document.body.dataset.mutated = 'yes';
    });
  </script>
</body>
</html>
`;

const CHILD = `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Fixture child</title></head>
<body><p id="child-text">${FIXTURE_CHILD_TEXT}</p></body>
</html>
`;

const MODELS = `${JSON.stringify({ data: [{ id: FIXTURE_MODEL_ID }] })}\n`;
const PROVIDER_RESPONSE = `${JSON.stringify({
  status: 'completed',
  output: [
    {
      type: 'message',
      content: [{ type: 'output_text', text: FIXTURE_PROVIDER_TEXT }],
    },
    {
      type: 'function_call',
      call_id: 'phase20-fixture-call',
      name: FIXTURE_PROVIDER_TOOL,
      arguments: '{}',
    },
  ],
  usage: { input_tokens: 7, output_tokens: 3 },
})}\n`;

const isRecord = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

const hasExactKeys = (value, keys) => {
  if (!isRecord(value)) return false;
  const actual = Object.keys(value).sort();
  const expected = [...keys].sort();
  return actual.length === expected.length
    && actual.every((key, index) => key === expected[index]);
};

const isBoundedString = (value, maxBytes, allowEmpty = true) =>
  typeof value === 'string'
  && (allowEmpty || value.length > 0)
  && Buffer.byteLength(value, 'utf8') <= maxBytes;

const isFixtureProviderRequest = (value) => {
  if (!hasExactKeys(value, [
    'input',
    'instructions',
    'max_output_tokens',
    'model',
    'parallel_tool_calls',
    'store',
    'tools',
  ])
      || value.model !== FIXTURE_MODEL_ID
      || value.store !== false
      || value.parallel_tool_calls !== false
      || !Number.isInteger(value.max_output_tokens)
      || value.max_output_tokens < 1
      || value.max_output_tokens > 32_768
      || !isBoundedString(value.instructions, 16 * 1024)
      || !Array.isArray(value.input)
      || value.input.length !== 1
      || !hasExactKeys(value.input[0], ['content', 'role'])
      || value.input[0].role !== 'user'
      || !isBoundedString(value.input[0].content, 64 * 1024, false)
      || !Array.isArray(value.tools)
      || value.tools.length !== 1) {
    return false;
  }
  const [tool] = value.tools;
  return hasExactKeys(tool, [
    'description',
    'name',
    'parameters',
    'strict',
    'type',
  ])
    && tool.type === 'function'
    && tool.name === FIXTURE_PROVIDER_TOOL
    && tool.strict === true
    && isBoundedString(tool.description, 4_096, false)
    && hasExactKeys(tool.parameters, ['additionalProperties', 'properties', 'type'])
    && tool.parameters.type === 'object'
    && tool.parameters.additionalProperties === false
    && isRecord(tool.parameters.properties)
    && Object.keys(tool.parameters.properties).length === 0;
};

const readBoundedRequest = async (request) => {
  const chunks = [];
  let total = 0;
  let tooLarge = false;
  for await (const chunk of request) {
    total += chunk.byteLength;
    if (total > MAX_FIXTURE_PROVIDER_REQUEST_BYTES) {
      tooLarge = true;
      chunks.length = 0;
    } else if (!tooLarge) {
      chunks.push(Buffer.from(chunk));
    }
  }
  return tooLarge ? null : Buffer.concat(chunks, total);
};

const send = (response, status, contentType, body) => {
  response.writeHead(status, {
    'Cache-Control': 'no-store',
    'Content-Length': Buffer.byteLength(body, 'utf8'),
    'Content-Type': contentType,
    'X-Content-Type-Options': 'nosniff',
  });
  response.end(body);
};

export const startFixtureServer = async ({
  host = '127.0.0.1',
  port = 0,
} = {}) => {
  if (!['127.0.0.1', '::1'].includes(host)
      || !Number.isInteger(port) || port < 0 || port > 65_535) {
    throw new TypeError('Fixture server requires a loopback port.');
  }
  const server = http.createServer((request, response) => {
    void (async () => {
      const requestUrl = new URL(request.url ?? '/', 'http://127.0.0.1');
      if (requestUrl.search.length > 0 || requestUrl.hash.length > 0) {
        send(response, 404, 'text/plain; charset=utf-8', 'not found\n');
        return;
      }
      if (requestUrl.pathname === '/' || requestUrl.pathname === '/child') {
        if (request.method !== 'GET') {
          send(response, 405, 'text/plain; charset=utf-8', 'method not allowed\n');
          return;
        }
        send(
          response,
          200,
          'text/html; charset=utf-8',
          requestUrl.pathname === '/' ? PAGE : CHILD,
        );
        return;
      }
      if (requestUrl.pathname === '/v1/models') {
        if (request.method !== 'GET') {
          request.resume();
          send(response, 405, 'text/plain; charset=utf-8', 'method not allowed\n');
          return;
        }
        send(response, 200, 'application/json; charset=utf-8', MODELS);
        return;
      }
      if (requestUrl.pathname === '/v1/responses') {
        if (request.method !== 'POST') {
          send(response, 405, 'text/plain; charset=utf-8', 'method not allowed\n');
          return;
        }
        const declaredLength = request.headers['content-length'];
        if ((declaredLength !== undefined
            && (!/^[0-9]+$/u.test(declaredLength)
              || Number(declaredLength) > MAX_FIXTURE_PROVIDER_REQUEST_BYTES))
            || !String(request.headers['content-type'] ?? '')
              .toLowerCase().startsWith('application/json')) {
          request.resume();
          send(response, 413, 'text/plain; charset=utf-8', 'request rejected\n');
          return;
        }
        const bytes = await readBoundedRequest(request);
        if (!bytes) {
          send(response, 413, 'text/plain; charset=utf-8', 'request too large\n');
          return;
        }
        let value;
        try {
          value = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
        } catch {
          send(response, 400, 'text/plain; charset=utf-8', 'invalid request\n');
          return;
        }
        if (!isFixtureProviderRequest(value)) {
          send(response, 400, 'text/plain; charset=utf-8', 'invalid request\n');
          return;
        }
        send(response, 200, 'application/json; charset=utf-8', PROVIDER_RESPONSE);
        return;
      }
      request.resume();
      send(response, 404, 'text/plain; charset=utf-8', 'not found\n');
    })().catch(() => {
      if (!response.headersSent) {
        send(response, 500, 'text/plain; charset=utf-8', 'fixture failure\n');
      } else {
        response.destroy();
      }
    });
  });
  server.on('clientError', (_error, socket) => socket.destroy());

  await new Promise((resolve, reject) => {
    const onError = (error) => {
      server.off('listening', onListening);
      reject(error);
    };
    const onListening = () => {
      server.off('error', onError);
      resolve();
    };
    server.once('error', onError);
    server.once('listening', onListening);
    server.listen({ host, port, exclusive: true });
  });
  const address = server.address();
  if (!address || typeof address === 'string' || address.address !== host) {
    server.close();
    throw new Error('Fixture server did not bind IPv4 loopback.');
  }
  const serializedHost = host === '::1' ? '[::1]' : host;
  const origin = `http://${serializedHost}:${address.port}`;
  let closePromise;
  return Object.freeze({
    origin,
    url: `${origin}/`,
    childUrl: `${origin}/child`,
    close: () => {
      closePromise ??= new Promise((resolve, reject) => {
        server.close((error) => error ? reject(error) : resolve());
        server.closeAllConnections?.();
      });
      return closePromise;
    },
  });
};

const isMain = process.argv[1]
  && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href;

if (isMain) {
  const readyFile = process.env.PROMETHEUS_MCP_FIXTURE_READY_FILE;
  if (!readyFile || !path.isAbsolute(readyFile)) {
    process.stderr.write('prometheus-mcp fixture: startup failed\n');
    process.exitCode = 1;
  } else {
    try {
      const fixture = await startFixtureServer({
        host: process.env.PROMETHEUS_MCP_FIXTURE_HOST ?? '127.0.0.1',
      });
      const handle = await open(readyFile, 'wx', 0o600);
      try {
        await handle.writeFile(`${JSON.stringify({
          origin: fixture.origin,
          url: fixture.url,
          pid: process.pid,
        })}\n`, 'utf8');
        await handle.sync();
      } finally {
        await handle.close();
      }
      let closing = false;
      const close = async () => {
        if (closing) return;
        closing = true;
        await fixture.close().catch(() => {});
      };
      process.once('SIGINT', () => void close());
      process.once('SIGTERM', () => void close());
    } catch {
      process.stderr.write('prometheus-mcp fixture: startup failed\n');
      process.exitCode = 1;
    }
  }
}
