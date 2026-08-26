import { config } from './config/index.js';
import { createApp } from './app.js';
import { installGracefulShutdown } from './lib/graceful-shutdown.js';

async function start() {
  const app = await createApp();
  installGracefulShutdown(app);

  try {
    await app.listen({ port: config.PORT, host: config.HOST });
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

start();
