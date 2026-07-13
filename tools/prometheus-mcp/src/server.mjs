import { FramingError, FramingParser } from './framing.mjs';
import { NativeClient } from './native-client.mjs';
import { jsonRpcParseError, McpProtocol } from './protocol.mjs';
import { BrowserSession } from './session.mjs';
import { createToolHandler } from './tool-handler.mjs';

const SIGNALS = ['SIGINT', 'SIGTERM'];
const SHUTDOWN_DRAIN_MS = 2_000;

const safeDiagnostic = (errorOutput, category) => {
  errorOutput.write(`prometheus-mcp: ${category}\n`);
};

const withDrainLimit = async (promise) => {
  let timer;
  const timeout = new Promise((resolve) => {
    timer = setTimeout(resolve, SHUTDOWN_DRAIN_MS);
    timer.unref?.();
  });
  await Promise.race([promise, timeout]);
  clearTimeout(timer);
};

export const createStdioServer = ({
  input = process.stdin,
  output = process.stdout,
  errorOutput = process.stderr,
  signalEmitter = process,
  listTools,
  callTool,
  onInitialize,
  onShutdown,
} = {}) => {
  const framing = new FramingParser();
  const protocol = new McpProtocol({
    listTools,
    callTool,
    onInitialize,
    onShutdown,
  });
  const pending = new Set();
  const signalHandlers = new Map(
    SIGNALS.map((signal) => [signal, () => onSignal(signal)]),
  );
  let finishPromise = null;
  let finishResolve;
  let stopped = false;
  let stopResolve;
  const stopRequested = new Promise((resolve) => { stopResolve = resolve; });

  const writeMessage = (message) => {
    output.write(framing.encode(message));
  };

  const finish = (reason, graceful = true) => {
    if (finishPromise) return finishPromise;
    stopped = true;
    stopResolve();
    finishPromise = new Promise((resolve) => { finishResolve = resolve; });
    void (async () => {
      const shutdown = protocol.shutdown(reason, { graceful });
      const drain = Promise.allSettled([...pending]);
      await withDrainLimit(Promise.allSettled([shutdown, drain]));
      finishResolve();
    })();
    return finishPromise;
  };

  const onSignal = (signal) => {
    void finish(signal, true);
    input.destroy?.();
  };

  const track = (promise) => {
    pending.add(promise);
    promise.finally(() => pending.delete(promise));
  };

  const run = async () => {
    for (const signal of SIGNALS) {
      signalEmitter.once(signal, signalHandlers.get(signal));
    }
    try {
      for await (const chunk of input) {
        if (stopped) break;
        let messages;
        try {
          messages = framing.push(chunk);
        } catch (error) {
          if (error instanceof FramingError) {
            writeMessage(jsonRpcParseError());
            safeDiagnostic(errorOutput, 'protocol input rejected');
            input.destroy?.();
            await finish('protocol-error', true);
            return;
          }
          throw error;
        }
        for (const message of messages) {
          const handling = protocol.handle(message, writeMessage);
          if (message?.method === 'initialize') {
            track(handling);
            await Promise.race([handling, stopRequested]);
            if (stopped) break;
          } else if (protocol.ready && message?.method === 'tools/call') {
            track(handling);
          } else {
            await handling;
          }
        }
      }
      await finish('EOF', true);
    } catch {
      if (!stopped) {
        safeDiagnostic(errorOutput, 'input stream failed');
        await finish('input-error', false);
      } else if (finishPromise) {
        await finishPromise;
      }
    } finally {
      for (const signal of SIGNALS) {
        signalEmitter.off(signal, signalHandlers.get(signal));
      }
    }
  };

  return {
    protocol,
    run,
    shutdown: finish,
  };
};

export const createPrometheusMcpServer = ({
  env = process.env,
  nativeClient: suppliedNativeClient,
  session: suppliedSession,
  errorOutput = process.stderr,
  ...stdioOptions
} = {}) => {
  const diagnostic = (category) => safeDiagnostic(errorOutput, category);
  const nativeClient = suppliedNativeClient ?? new NativeClient({ env });
  const session = suppliedSession ?? new BrowserSession({
    nativeClient,
    env,
    diagnostic,
  });
  const tools = createToolHandler({ session, diagnostic });
  return createStdioServer({
    ...stdioOptions,
    errorOutput,
    listTools: tools.listTools,
    callTool: tools.callTool,
    onInitialize: (clientInfo) => session.initialize(clientInfo),
    onShutdown: ({ graceful }) => session.shutdown({ graceful }),
  });
};
