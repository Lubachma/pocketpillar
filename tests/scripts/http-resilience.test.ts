import { describe, it, expect, vi } from 'vitest';
import { resilientFetch, timeoutFetch } from '../../src/scripts/http-resilience.js';

/** Instant retries: the production backoff has no place in a test run. */
const NO_DELAYS: readonly number[] = [0, 0];

const ok = () => new Response('{}', { status: 200 });

describe('resilientFetch', () => {
  it('returns the first successful response without retrying', async () => {
    const fetchImpl = vi.fn(async () => ok());

    const response = await resilientFetch('https://api.test/x', {}, fetchImpl, NO_DELAYS);

    expect(response.status).toBe(200);
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it('retries a thrown network error, then succeeds', async () => {
    const fetchImpl = vi
      .fn<typeof fetch>()
      .mockRejectedValueOnce(new TypeError('fetch failed'))
      .mockResolvedValueOnce(ok());

    const response = await resilientFetch('https://api.test/x', {}, fetchImpl, NO_DELAYS);

    expect(response.status).toBe(200);
    expect(fetchImpl).toHaveBeenCalledTimes(2);
  });

  it('retries a proxy 503 (machine waking up), then succeeds', async () => {
    const fetchImpl = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(new Response('wake', { status: 503 }))
      .mockResolvedValueOnce(ok());

    const response = await resilientFetch('https://api.test/x', {}, fetchImpl, NO_DELAYS);

    expect(response.status).toBe(200);
    expect(fetchImpl).toHaveBeenCalledTimes(2);
  });

  it('exhausted retries: throws the LAST error instead of hanging', async () => {
    const fetchImpl = vi.fn<typeof fetch>().mockRejectedValue(new TypeError('fetch failed'));

    await expect(resilientFetch('https://api.test/x', {}, fetchImpl, NO_DELAYS)).rejects.toThrow(
      'fetch failed',
    );
    // 1 initial attempt + 2 retries.
    expect(fetchImpl).toHaveBeenCalledTimes(3);
  });

  it('a deterministic HTTP error (4xx/plain 500) is returned as-is, no retry', async () => {
    const fetchImpl = vi.fn(async () => new Response('{"error":"x"}', { status: 500 }));

    const response = await resilientFetch('https://api.test/x', {}, fetchImpl, NO_DELAYS);

    expect(response.status).toBe(500);
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it('every attempt carries an abort signal (no more 300 s undici hangs)', async () => {
    const fetchImpl = vi.fn(async (_url: unknown, init?: RequestInit) => {
      expect(init?.signal).toBeInstanceOf(AbortSignal);
      return ok();
    });

    await resilientFetch('https://api.test/x', {}, fetchImpl as typeof fetch, NO_DELAYS);

    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });
});

describe('timeoutFetch', () => {
  it('wraps the fetch with an abort signal and changes nothing else', async () => {
    const fetchImpl = vi.fn(async (_url: unknown, init?: RequestInit) => {
      expect(init?.signal).toBeInstanceOf(AbortSignal);
      expect(init?.method).toBe('POST');
      return ok();
    });

    const wrapped = timeoutFetch(fetchImpl as typeof fetch);
    const response = await wrapped('https://supabase.test/auth', { method: 'POST' });

    expect(response.status).toBe(200);
  });
});
