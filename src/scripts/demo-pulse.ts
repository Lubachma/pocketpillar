/**
 * Demo "pulse": daily push notification via ntfy.sh
 * (private topic in the NTFY_TOPIC env var — absent = feature inactive).
 *
 * The connection count comes from server-side technical logs
 * (today's `auth.sessions` table, counted by reset-demo before the purge) —
 * no client-side cookie or tracker, compliant with the privacy policy.
 * Sending must NEVER make the reset fail: silent best-effort.
 */

export interface PulseMessage {
  title: string;
  body: string;
}

export function formatPulse(sessions: number, options: { failed?: boolean } = {}): PulseMessage {
  const count =
    sessions === 0 ? 'aucune connexion' : sessions === 1 ? '1 connexion' : `${sessions} connexions`;
  // Titles in pure ASCII: they go out as an HTTP header (latin-1/ASCII
  // only — an accent there becomes mojibake). The body stays UTF-8.
  if (options.failed) {
    return {
      title: 'PocketPillar demo - reset en ECHEC',
      body: `${count} depuis le dernier reset. Voir fly logs --app pocketpillar-api.`,
    };
  }
  return {
    title: 'PocketPillar demo',
    body: `Reset OK — ${count} depuis le dernier reset.`,
  };
}

export async function sendPulse(
  topic: string,
  sessions: number,
  options: { failed?: boolean } = {},
  fetchImpl: typeof fetch = fetch,
): Promise<void> {
  const message = formatPulse(sessions, options);
  try {
    await fetchImpl(`https://ntfy.sh/${topic}`, {
      method: 'POST',
      headers: {
        Title: message.title,
        Tags: options.failed ? 'rotating_light' : 'chart_with_upwards_trend',
      },
      body: message.body,
    });
  } catch (error) {
    console.warn('pulse ntfy non envoyé (sans gravité):', error);
  }
}
