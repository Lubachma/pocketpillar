import { describe, it, expect, vi, afterEach } from 'vitest';
import Fastify from 'fastify';
import { installGracefulShutdown } from '../../src/lib/graceful-shutdown.js';

/**
 * process.exit is stubbed so the worker survives; each test uninstalls the
 * signal handlers it installed so they cannot leak into the next test.
 */
describe('installGracefulShutdown', () => {
  const exitSpy = vi.spyOn(process, 'exit').mockImplementation(() => undefined as never);
  let uninstall: (() => void) | undefined;

  afterEach(() => {
    uninstall?.();
    uninstall = undefined;
    vi.clearAllMocks();
  });

  it('SIGTERM closes the app (onClose hooks run) then exits 0', async () => {
    const app = Fastify({ logger: false });
    const onClose = vi.fn();
    app.addHook('onClose', async () => {
      onClose();
    });
    uninstall = installGracefulShutdown(app);

    process.emit('SIGTERM');

    await vi.waitFor(() => expect(exitSpy).toHaveBeenCalledWith(0));
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('SIGINT also triggers the shutdown', async () => {
    const app = Fastify({ logger: false });
    const closeSpy = vi.spyOn(app, 'close');
    uninstall = installGracefulShutdown(app);

    process.emit('SIGINT');

    await vi.waitFor(() => expect(exitSpy).toHaveBeenCalledWith(0));
    expect(closeSpy).toHaveBeenCalledTimes(1);
  });

  it('a second signal does not close the app twice', async () => {
    const app = Fastify({ logger: false });
    const closeSpy = vi.spyOn(app, 'close');
    uninstall = installGracefulShutdown(app);

    process.emit('SIGTERM');
    process.emit('SIGINT');

    await vi.waitFor(() => expect(exitSpy).toHaveBeenCalledWith(0));
    expect(closeSpy).toHaveBeenCalledTimes(1);
  });

  it('force-exits 1 when app.close() hangs past the failsafe', async () => {
    const app = {
      log: { info: vi.fn(), error: vi.fn() },
      close: vi.fn(() => new Promise<void>(() => {})), // never resolves
    };
    uninstall = installGracefulShutdown(app as never, 30);

    process.emit('SIGTERM');

    await vi.waitFor(() => expect(exitSpy).toHaveBeenCalledWith(1));
  });

  it('exits 1 when app.close() rejects', async () => {
    const app = {
      log: { info: vi.fn(), error: vi.fn() },
      close: vi.fn().mockRejectedValue(new Error('close failed')),
    };
    uninstall = installGracefulShutdown(app as never);

    process.emit('SIGTERM');

    await vi.waitFor(() => expect(exitSpy).toHaveBeenCalledWith(1));
  });
});
