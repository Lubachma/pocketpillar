import { describe, expect, it, vi } from 'vitest';
import { formatPulse, sendPulse } from '../../src/scripts/demo-pulse.js';

describe('demo pulse', () => {
  it('formats the message according to the number of connections', () => {
    expect(formatPulse(0).body).toContain('aucune connexion');
    expect(formatPulse(1).body).toContain('1 connexion');
    expect(formatPulse(4).body).toContain('4 connexions');
    expect(formatPulse(4).title).toContain('PocketPillar');
  });

  it('signals a reset failure with a distinct title (ASCII — HTTP header)', () => {
    const failure = formatPulse(2, { failed: true });
    expect(failure.title).toContain('ECHEC');
    expect(failure.body).toContain('fly logs');
    // Titles go into an HTTP header: pure ASCII is mandatory.
    expect(formatPulse(1).title).toMatch(/^[\x20-\x7E]+$/);
    expect(failure.title).toMatch(/^[\x20-\x7E]+$/);
  });

  it('posts to ntfy.sh with the topic, title and body', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true });
    await sendPulse('topic-prive-123', 3, {}, fetchMock);

    expect(fetchMock).toHaveBeenCalledOnce();
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://ntfy.sh/topic-prive-123');
    expect(init.method).toBe('POST');
    expect((init.headers as Record<string, string>).Title).toContain('PocketPillar');
    expect(String(init.body)).toContain('3 connexions');
  });

  it('a send failure never throws (the reset must not depend on it)', async () => {
    const fetchMock = vi.fn().mockRejectedValue(new Error('réseau'));
    await expect(sendPulse('topic', 1, {}, fetchMock)).resolves.toBeUndefined();
  });
});
