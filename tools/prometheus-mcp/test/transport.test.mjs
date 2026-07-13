import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const fixture = JSON.parse(
  await readFile(new URL('fixtures/protocol-cases.json', import.meta.url), 'utf8'),
);

test('Wave 0 newline and Content-Length fixtures are internally valid', () => {
  const newline = fixture.transport.newline;
  assert.ok(newline.encoded.endsWith('\n'));
  assert.deepEqual(JSON.parse(newline.encoded.trimEnd()), newline.message);

  const legacy = fixture.transport.content_length;
  const [header, body] = legacy.encoded.split('\r\n\r\n');
  assert.equal(header, `Content-Length: ${legacy.body_bytes}`);
  assert.equal(Buffer.byteLength(body, 'utf8'), legacy.body_bytes);
  assert.deepEqual(JSON.parse(body), legacy.message);
  assert.equal(fixture.transport.oversized_input_bytes, 1_048_577);
});

test('Wave 0 protocol outcomes retain structured/text parity', () => {
  assert.equal(fixture.protocol.initialize.request.method, 'initialize');
  assert.equal(fixture.protocol.initialize.result.protocolVersion, '2025-11-25');
  for (const outcome of [
    fixture.protocol.tool_success,
    fixture.protocol.tool_error,
  ]) {
    assert.deepEqual(JSON.parse(outcome.content[0].text), outcome.structuredContent);
  }
  assert.equal(fixture.protocol.cancellation.method, 'notifications/cancelled');
  assert.ok(fixture.transport.malformed.length > 0);
});

test.todo('Plan 19-06: parse fragmented and multiple newline JSON-RPC frames');
test.todo('Plan 19-06: select and lock legacy Content-Length framing');
test.todo('Plan 19-06: negotiate initialize and initialized lifecycle');
test.todo('Plan 19-06: cancel an in-flight request without duplicate output');
test.todo('Plan 19-06: reject malformed and oversized protocol input');
