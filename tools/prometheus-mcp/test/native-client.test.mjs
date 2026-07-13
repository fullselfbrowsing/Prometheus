import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

import { getToolDefinition } from '../src/catalog.mjs';
import { normalizeToolArguments } from '../src/schema.mjs';

const fixture = JSON.parse(
  await readFile(new URL('fixtures/protocol-cases.json', import.meta.url), 'utf8'),
);

test('Wave 0 descriptor is a loopback-only authenticated contract', () => {
  const { descriptor, authorization, endpoints } = fixture.native;
  assert.equal(descriptor.protocol, 'prometheus-agent-v1');
  const endpoint = new URL(descriptor.endpoint);
  assert.equal(endpoint.protocol, 'http:');
  assert.equal(endpoint.hostname, '127.0.0.1');
  assert.equal(authorization, `Bearer ${descriptor.bearer}`);
  assert.ok(Number.isInteger(descriptor.pid) && descriptor.pid > 0);
  assert.ok(descriptor.instance_nonce.length > 0);
  assert.deepEqual(endpoints, [
    'POST /v1/session/create',
    'POST /v1/session/resume',
    'POST /v1/session/touch',
    'POST /v1/session/close',
    'POST /v1/agent/command',
    'GET /v1/health',
  ]);
});

test('Wave 0 native request arguments already use strict catalog normalization', () => {
  const request = normalizeToolArguments(getToolDefinition('navigate'), {
    tabId: '42',
    url: 'https://example.test/',
    client: 'codex',
  });
  assert.deepEqual(request, {
    target: { tab_id: 42 },
    url: 'https://example.test/',
    client: 'Codex',
  });
});

test.todo('Plan 19-05: authenticate all six native gateway endpoints');
test.todo('Plan 19-06: discover and validate the owner-only descriptor');
test.todo('Plan 19-06: create, touch, resume, and close one browser session');
test.todo('Plan 19-06: bound and cancel native bearer requests');
