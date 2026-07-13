#!/usr/bin/env node

import { createStdioServer } from '../src/server.mjs';

const server = createStdioServer();
await server.run();
