/**
 * Short timeouts and retries for the demo-reset's outbound calls.
 *
 * Lesson of the 2026-08-28 incident: the API runs with
 * `min_machines_running = 0`, and a fetch against the stopped machine
 * was held by the Fly proxy until undici's 300 s headers timeout —
 * twice — while the demo account had already been deleted. Every call
 * now gets a SHORT timeout, transient failures are retried, and a run
 * must fail (and be re-run by Fly's restart policy) within minutes,
 * not hours.
 */

export const REQUEST_TIMEOUT_MS = 15_000;

/** Between attempts: enough for a Fly machine cold start, not more. */
const RETRY_DELAYS_MS: readonly number[] = [5_000, 15_000];

/** Proxy-side statuses seen while the target machine wakes up. */
const TRANSIENT_STATUSES = new Set([502, 503, 504]);

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * `fetch` with a per-attempt timeout, retried on network failures and
 * proxy 502/503/504. Any other response (2xx, 4xx, 5xx) is returned
 * as-is — deterministic HTTP errors are the caller's business, not a
 * reason to hammer the API.
 */
export async function resilientFetch(
  url: string,
  init: RequestInit = {},
  fetchImpl: typeof fetch = fetch,
  delays: readonly number[] = RETRY_DELAYS_MS,
): Promise<Response> {
  let lastError: unknown;
  for (let attempt = 0; attempt <= delays.length; attempt += 1) {
    if (attempt > 0) await sleep(delays[attempt - 1] ?? 0);
    try {
      const response = await fetchImpl(url, {
        ...init,
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
      if (TRANSIENT_STATUSES.has(response.status) && attempt < delays.length) {
        lastError = new Error(`HTTP ${response.status} (transitoire)`);
        continue;
      }
      return response;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError;
}

/**
 * A `fetch` that only adds the short timeout — for the supabase-js
 * clients (`global.fetch`): their own error handling stays in charge,
 * but no call may hang for undici's 300 s default anymore.
 */
export function timeoutFetch(fetchImpl: typeof fetch = fetch): typeof fetch {
  return (input, init) =>
    fetchImpl(input, { ...init, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) });
}
