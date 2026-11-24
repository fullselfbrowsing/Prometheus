#!/usr/bin/env node

import { createPrometheusMcpServer } from '../src/server.mjs';

try {
  const server = createPrometheusMcpServer();
  await server.run();
} catch {
  process.stderr.write('prometheus-mcp: startup failed\n');
  process.exitCode = 1;
}
