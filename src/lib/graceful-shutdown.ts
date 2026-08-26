import type { FastifyInstance } from 'fastify';

/** Failsafe: if app.close() hangs, force-exit after this delay. */
const SHUTDOWN_TIMEOUT_MS = 10_000;

/**
 * Graceful shutdown: on SIGTERM/SIGINT, close Fastify — which runs the onClose
 * hooks (prisma $disconnect, redis quit) — then exit 0. A hanging close is
 * bounded by a failsafe timer that forces exit 1.
 *
 * Returns an uninstall function (used by tests).
 */
export function installGracefulShutdown(
  app: FastifyInstance,
  timeoutMs = SHUTDOWN_TIMEOUT_MS,
): () => void {
  let shuttingDown = false;

  const shutdown = (signal: string) => {
    // A second signal (e.g. SIGINT after SIGTERM) must not close() twice.
    if (shuttingDown) return;
    shuttingDown = true;
    app.log.info({ signal }, 'Shutdown signal received');

    const failsafe = setTimeout(() => {
      app.log.error('Graceful shutdown timed out — forcing exit');
      process.exit(1);
    }, timeoutMs);
    // The failsafe alone must not keep the event loop alive.
    failsafe.unref();

    app
      .close()
      .then(() => process.exit(0))
      .catch((err) => {
        app.log.error({ err }, 'Graceful shutdown failed');
        process.exit(1);
      });
  };

  const onSigterm = () => shutdown('SIGTERM');
  const onSigint = () => shutdown('SIGINT');
  process.once('SIGTERM', onSigterm);
  process.once('SIGINT', onSigint);

  return () => {
    process.removeListener('SIGTERM', onSigterm);
    process.removeListener('SIGINT', onSigint);
  };
}
