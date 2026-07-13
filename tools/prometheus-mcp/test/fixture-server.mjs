#!/usr/bin/env node

import { open } from 'node:fs/promises';
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export const FIXTURE_PAGE_TEXT = 'Prometheus MCP fixture page text';
export const FIXTURE_CHILD_TEXT = 'Prometheus MCP same-origin child text';

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
    if (request.method !== 'GET') {
      send(response, 405, 'text/plain; charset=utf-8', 'method not allowed\n');
      return;
    }
    const requestUrl = new URL(request.url ?? '/', 'http://127.0.0.1');
    if (requestUrl.pathname === '/') {
      send(response, 200, 'text/html; charset=utf-8', PAGE);
    } else if (requestUrl.pathname === '/child') {
      send(response, 200, 'text/html; charset=utf-8', CHILD);
    } else {
      send(response, 404, 'text/plain; charset=utf-8', 'not found\n');
    }
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
