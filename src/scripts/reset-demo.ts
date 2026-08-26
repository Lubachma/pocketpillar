/**
 * Nightly reset of the public demo account.
 *
 * Replays the REAL endpoints (same flows as scripts/smoke-api.sh):
 * full account deletion (DELETE /users/me — wipes DB + Storage +
 * auth), admin recreation (email_confirm, zero email — anti-bounce lesson from
 * 12.08.2026), profile rebuild, example PDF upload, then premium via a
 * direct write to `subscriptions` (backend source of truth, no RevenueCat
 * dependency). The userId changes on every reset → no stale Redis cache to
 * invalidate. Intentional side effect: daily activity = keep-alive for the
 * Supabase free-tier project.
 *
 * If the auth password no longer matches (DEMO_PASSWORD rotation, leftover
 * from a local test), the auth user is deleted on the admin side and the
 * orphaned `users` row purged via Prisma before recreation.
 *
 * Execution: daily Fly scheduled machine —
 * `node dist/scripts/reset-demo.js`.
 */
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { createClient } from '@supabase/supabase-js';

import {
  DEMO_DOCUMENT,
  DEMO_FINANCIAL_PROFILE,
  DEMO_PILLAR2,
  DEMO_PILLAR3A,
  DEMO_TAX,
  DEMO_USER_PATCH,
  demoSubscriptionData,
} from './demo-fixtures.js';
import { sendPulse } from './demo-pulse.js';

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`env ${name} manquante`);
  return value;
}

const SUPABASE_URL = requireEnv('SUPABASE_URL');
const ANON_KEY = requireEnv('SUPABASE_ANON_KEY');
const SERVICE_KEY = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
const DEMO_EMAIL = requireEnv('DEMO_EMAIL');
const DEMO_PASSWORD = requireEnv('DEMO_PASSWORD');
const API = process.env.DEMO_API_URL ?? 'https://api.pocketpillar.ch';
/** ntfy.sh topic for the daily "pulse" — absent = no notification. */
const NTFY_TOPIC = process.env.NTFY_TOPIC ?? '';

/** Connections counted before the purge (server-side technical logs). */
let sessionsSinceReset = 0;

const authOptions = { auth: { autoRefreshToken: false, persistSession: false } };
const admin = createClient(SUPABASE_URL, SERVICE_KEY, authOptions);
const anon = createClient(SUPABASE_URL, ANON_KEY, authOptions);

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: requireEnv('DATABASE_URL') }),
});

async function signIn(): Promise<string | null> {
  const { data } = await anon.auth.signInWithPassword({
    email: DEMO_EMAIL,
    password: DEMO_PASSWORD,
  });
  return data.session?.access_token ?? null;
}

async function api(
  token: string,
  method: string,
  path: string,
  body?: unknown,
): Promise<Record<string, unknown>> {
  const response = await fetch(`${API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const parsed = (await response.json().catch(() => ({}))) as Record<string, unknown>;
  if (!response.ok) {
    throw new Error(`${method} ${path} → ${response.status} ${JSON.stringify(parsed)}`);
  }
  return parsed;
}

/** Auth id of the demo user, or null if it doesn't exist. */
async function findAuthUserIdByEmail(): Promise<string | null> {
  for (let page = 1; page <= 10; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) throw new Error(`listUsers: ${error.message}`);
    const match = data.users.find((u) => u.email === DEMO_EMAIL);
    if (match) return match.id;
    if (data.users.length < 1000) break;
  }
  return null;
}

/**
 * Connections since the last reset: since the account is recreated on every
 * reset, all its `auth.sessions` rows postdate it — one visitor login = one
 * session. Server-side technical logs only (no client-side tracker —
 * compliant with the privacy policy).
 */
async function countSessions(authUserId: string): Promise<number> {
  const rows = await prisma.$queryRaw<Array<{ n: bigint }>>`
    select count(*)::bigint as n from auth.sessions where user_id = ${authUserId}::uuid`;
  return Number(rows[0]?.n ?? 0n);
}

/** Purges the auth user (lost/rotated password) + orphaned users row. */
async function adminPurgeByEmail(): Promise<void> {
  const id = await findAuthUserIdByEmail();
  if (id) {
    const { error: deleteError } = await admin.auth.admin.deleteUser(id);
    if (deleteError) throw new Error(`deleteUser: ${deleteError.message}`);
    console.log('utilisateur auth existant purgé (mot de passe non concordant)');
  }
  // Possible orphaned backend row (cascades to profile/documents in DB).
  await prisma.user.deleteMany({ where: { email: DEMO_EMAIL } });
}

async function main(): Promise<void> {
  // 0 — Pulse: count the outgoing account's connections before the purge.
  const previousAuthId = await findAuthUserIdByEmail();
  if (previousAuthId) {
    try {
      sessionsSinceReset = await countSessions(previousAuthId);
    } catch (error) {
      console.warn('comptage des sessions impossible (sans gravité):', error);
    }
  }

  // 1 — Purge: via the API if the password still works (also cleans up
  // Storage), otherwise on the admin side.
  const oldToken = await signIn();
  if (oldToken) {
    await api(oldToken, 'DELETE', '/users/me');
    console.log('ancien compte démo supprimé (DB + Storage + auth)');
  } else {
    await adminPurgeByEmail();
  }

  // 2 — Admin recreation, pre-confirmed email (no email sent).
  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email: DEMO_EMAIL,
    password: DEMO_PASSWORD,
    email_confirm: true,
  });
  if (createError || !created.user) {
    throw new Error(`création admin échouée: ${createError?.message}`);
  }
  const supabaseId = created.user.id;

  const token = await signIn();
  if (!token) throw new Error('login démo impossible après création');

  // 3 — Profile rebuild via the real endpoints.
  const registered = await api(token, 'POST', '/auth/register', {
    supabaseId,
    email: DEMO_EMAIL,
  });
  const userId = registered.id as string;
  await api(token, 'PATCH', '/users/me', DEMO_USER_PATCH);
  await api(token, 'PUT', '/financial-profile', DEMO_FINANCIAL_PROFILE);
  await api(token, 'POST', '/financial-profile/pillar2', DEMO_PILLAR2);
  await api(token, 'POST', '/financial-profile/pillar3a', DEMO_PILLAR3A);
  await api(token, 'PUT', '/financial-profile/tax', DEMO_TAX);

  // 4 — Example document (multipart: `type` field BEFORE `file`, contract §5).
  const form = new FormData();
  form.append('type', DEMO_DOCUMENT.type);
  form.append(
    'file',
    new Blob([DEMO_DOCUMENT.bytes()], { type: DEMO_DOCUMENT.mimeType }),
    DEMO_DOCUMENT.filename,
  );
  const upload = await fetch(`${API}/documents`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: form,
  });
  if (!upload.ok) {
    throw new Error(`upload document → ${upload.status} ${await upload.text()}`);
  }

  // 5 — Premium: direct write to the source of truth (no RevenueCat).
  const data = demoSubscriptionData(new Date());
  await prisma.subscription.upsert({
    where: { userId },
    create: { userId, ...data },
    update: data,
  });

  // 6 — Final check: the API must see the account as premium.
  const me = await api(token, 'GET', '/users/me');
  const premium = me.premium as { active?: boolean } | undefined;
  if (premium?.active !== true) {
    throw new Error(`le compte démo n'est pas premium: ${JSON.stringify(me.premium)}`);
  }
  console.log(
    `reset démo OK — userId ${userId}, premium actif, ` +
      `${sessionsSinceReset} connexion(s) depuis le dernier reset`,
  );
  if (NTFY_TOPIC) await sendPulse(NTFY_TOPIC, sessionsSinceReset);
}

main()
  .catch(async (error: unknown) => {
    console.error('reset démo ÉCHOUÉ:', error);
    process.exitCode = 1;
    if (NTFY_TOPIC) {
      await sendPulse(NTFY_TOPIC, sessionsSinceReset, { failed: true });
    }
  })
  .finally(() => prisma.$disconnect());
