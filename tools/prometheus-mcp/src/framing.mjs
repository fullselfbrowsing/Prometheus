const HEADER_PREFIX = Buffer.from('content-length:', 'ascii');
const HEADER_TERMINATOR = Buffer.from('\r\n\r\n', 'ascii');
const MAX_HEADER_BYTES = 8_192;

export const MAX_MESSAGE_BYTES = 1_048_576;

export class FramingError extends Error {
  constructor(code) {
    super(code);
    this.name = 'FramingError';
    this.code = code;
  }
}

const fail = (code) => {
  throw new FramingError(code);
};

const append = (left, right) => {
  const bytes = Buffer.isBuffer(right) ? right : Buffer.from(right);
  return left.length === 0 ? Buffer.from(bytes) : Buffer.concat([left, bytes]);
};

const decodeUtf8 = (bytes) => {
  try {
    return new TextDecoder('utf-8', { fatal: true }).decode(bytes);
  } catch {
    return fail('INVALID_UTF8');
  }
};

const parseJson = (bytes) => {
  const text = decodeUtf8(bytes);
  try {
    return JSON.parse(text);
  } catch {
    return fail('INVALID_JSON');
  }
};

const isHeaderPrefix = (bytes) => {
  const compared = Math.min(bytes.length, HEADER_PREFIX.length);
  return bytes.subarray(0, compared).toString('ascii').toLowerCase()
    === HEADER_PREFIX.subarray(0, compared).toString('ascii');
};

export class FramingParser {
  #buffer = Buffer.alloc(0);
  #mode = null;

  get mode() {
    return this.#mode;
  }

  push(chunk) {
    if (chunk === undefined || chunk === null) {
      fail('INVALID_CHUNK');
    }
    this.#buffer = append(this.#buffer, chunk);
    this.#selectMode();
    if (this.#mode === 'content-length') {
      return this.#readLegacyFrames();
    }
    if (this.#mode === 'newline') {
      return this.#readNewlineFrames();
    }
    return [];
  }

  encode(message) {
    const body = Buffer.from(JSON.stringify(message), 'utf8');
    if (body.length > MAX_MESSAGE_BYTES) {
      fail('MESSAGE_TOO_LARGE');
    }
    if (this.#mode === 'content-length') {
      return Buffer.concat([
        Buffer.from(`Content-Length: ${body.length}\r\n\r\n`, 'ascii'),
        body,
      ]);
    }
    return Buffer.concat([body, Buffer.from('\n', 'ascii')]);
  }

  #selectMode() {
    if (this.#mode !== null || this.#buffer.length === 0) {
      return;
    }
    if (isHeaderPrefix(this.#buffer)) {
      if (this.#buffer.length >= HEADER_PREFIX.length) {
        this.#mode = 'content-length';
      } else if (this.#buffer.length > MAX_HEADER_BYTES) {
        fail('INVALID_HEADER');
      }
      return;
    }
    this.#mode = 'newline';
  }

  #readNewlineFrames() {
    const messages = [];
    for (;;) {
      const newline = this.#buffer.indexOf(0x0a);
      if (newline === -1) {
        if (this.#buffer.length > MAX_MESSAGE_BYTES) {
          fail('MESSAGE_TOO_LARGE');
        }
        return messages;
      }
      let line = this.#buffer.subarray(0, newline);
      this.#buffer = this.#buffer.subarray(newline + 1);
      if (line.at(-1) === 0x0d) {
        line = line.subarray(0, line.length - 1);
      }
      if (line.length === 0) {
        continue;
      }
      if (line.length > MAX_MESSAGE_BYTES) {
        fail('MESSAGE_TOO_LARGE');
      }
      messages.push(parseJson(line));
    }
  }

  #readLegacyFrames() {
    const messages = [];
    for (;;) {
      if (this.#buffer.length === 0) {
        return messages;
      }
      if (!isHeaderPrefix(this.#buffer)) {
        fail('INVALID_HEADER');
      }
      if (this.#buffer.length < HEADER_PREFIX.length) {
        return messages;
      }
      const headerEnd = this.#buffer.indexOf(HEADER_TERMINATOR);
      if (headerEnd === -1) {
        if (this.#buffer.length > MAX_HEADER_BYTES) {
          fail('INVALID_HEADER');
        }
        return messages;
      }
      if (headerEnd > MAX_HEADER_BYTES) {
        fail('INVALID_HEADER');
      }
      const headerText = decodeUtf8(this.#buffer.subarray(0, headerEnd));
      const lengthValues = headerText
        .split('\r\n')
        .map((line) => /^content-length\s*:\s*([0-9]+)$/iu.exec(line))
        .filter(Boolean)
        .map((match) => match[1]);
      if (lengthValues.length !== 1) {
        fail('INVALID_HEADER');
      }
      const bodyLength = Number(lengthValues[0]);
      if (!Number.isSafeInteger(bodyLength) || bodyLength > MAX_MESSAGE_BYTES) {
        fail('MESSAGE_TOO_LARGE');
      }
      const bodyStart = headerEnd + HEADER_TERMINATOR.length;
      const frameEnd = bodyStart + bodyLength;
      if (this.#buffer.length < frameEnd) {
        return messages;
      }
      const body = this.#buffer.subarray(bodyStart, frameEnd);
      this.#buffer = this.#buffer.subarray(frameEnd);
      messages.push(parseJson(body));
    }
  }
}
