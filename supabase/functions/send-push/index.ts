// Delivers pending notifications as push messages through FCM HTTP v1.
//
// Trigger it with a Supabase Database Webhook on INSERT into
// public.notifications (fast path) and with a scheduled call every minute
// (retries). Both must send the header `x-push-secret: <PUSH_WEBHOOK_SECRET>`.
//
// Secrets (supabase secrets set ...):
//   PUSH_WEBHOOK_SECRET   random string shared with the webhook / cron job
//   FCM_SERVICE_ACCOUNT   the Firebase service-account JSON (one line)
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.
//
// Delivery is at-least-once: rows are claimed with SKIP LOCKED and marked
// after sending, and the device collapses repeats by notification id.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type Token = { token: string; platform: string; locale: string }
type Claimed = {
  id: number
  recipient_id: string
  type: string
  title: string
  body: string
  title_ar: string | null
  body_ar: string | null
  data: Record<string, unknown>
  tokens: Token[]
}

const MAX_ATTEMPTS = 5

Deno.serve(async (req: Request) => {
  const secret = Deno.env.get('PUSH_WEBHOOK_SECRET')
  if (!secret || req.headers.get('x-push-secret') !== secret) {
    return new Response('Forbidden', { status: 403 })
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { persistSession: false, autoRefreshToken: false } },
  )

  const serviceAccount = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT') ?? '{}')
  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    return new Response('FCM_SERVICE_ACCOUNT is not configured', { status: 500 })
  }

  const { data: batch, error } = await db.rpc('push_claim_batch', { p_limit: 50 })
  if (error) return new Response(error.message, { status: 500 })

  const claimed = (batch ?? []) as Claimed[]
  if (claimed.length === 0) return Response.json({ sent: 0 })

  const accessToken = await googleAccessToken(serviceAccount)
  let sent = 0

  for (const n of claimed) {
    if (n.tokens.length === 0) {
      await db.rpc('push_mark_result', { p_id: n.id, p_status: 'skipped' })
      continue
    }
    let delivered = false
    let lastError = ''
    for (const t of n.tokens) {
      const result = await sendOne(serviceAccount.project_id, accessToken, n, t)
      if (result.ok) {
        delivered = true
      } else {
        lastError = result.error
        if (result.deadToken) {
          await db.rpc('push_remove_token', { p_token: t.token })
        }
      }
    }
    // Delivered to at least one device counts as sent; otherwise it is
    // retried by the next run until MAX_ATTEMPTS (counted by the claim).
    await db.rpc('push_mark_result', {
      p_id: n.id,
      p_status: delivered ? 'sent' : 'failed',
      p_error: delivered ? null : lastError || `failed (max ${MAX_ATTEMPTS} attempts)`,
    })
    if (delivered) sent++
  }

  return Response.json({ claimed: claimed.length, sent })
})

async function sendOne(
  projectId: string,
  accessToken: string,
  n: Claimed,
  t: Token,
): Promise<{ ok: boolean; error: string; deadToken: boolean }> {
  const arabic = t.locale === 'ar'
  const title = arabic && n.title_ar ? n.title_ar : n.title
  const body = arabic && n.body_ar ? n.body_ar : n.body
  const tag = `efs-${n.id}`

  // Data values must be strings. Only ids travel here, never coordinates;
  // the app re-reads the target with the user's own permissions.
  const data: Record<string, string> = { notification_id: String(n.id), type: n.type }
  for (const [key, value] of Object.entries(n.data ?? {})) {
    if (value !== null && value !== undefined) data[key] = String(value)
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: t.token,
          notification: { title, body },
          data,
          android: {
            priority: 'high',
            collapse_key: tag,
            notification: { channel_id: 'efs_notifications', tag },
          },
          apns: {
            headers: { 'apns-collapse-id': tag, 'apns-priority': '10' },
            payload: { aps: { sound: 'default' } },
          },
        },
      }),
    },
  )
  if (response.ok) return { ok: true, error: '', deadToken: false }

  const text = await response.text()
  // UNREGISTERED (404) or an invalid token (400 INVALID_ARGUMENT): remove it.
  const deadToken =
    response.status === 404 ||
    (response.status === 400 && text.includes('INVALID_ARGUMENT') && text.includes('token'))
  return { ok: false, error: `${response.status} ${text.slice(0, 300)}`, deadToken }
}

let cachedToken: { value: string; expires: number } | null = null

/** OAuth2 access token for FCM from the service account (JWT bearer flow). */
async function googleAccessToken(sa: { client_email: string; private_key: string }) {
  const now = Math.floor(Date.now() / 1000)
  if (cachedToken && cachedToken.expires > now + 60) return cachedToken.value

  const header = { alg: 'RS256', typ: 'JWT' }
  const claims = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }
  const encode = (value: unknown) =>
    base64Url(new TextEncoder().encode(JSON.stringify(value)))
  const unsigned = `${encode(header)}.${encode(claims)}`

  const pem = sa.private_key.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '')
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0))
  const key = await crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const signature = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned)),
  )
  const assertion = `${unsigned}.${base64Url(signature)}`

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  })
  if (!response.ok) throw new Error(`Google token error ${response.status}`)
  const json = await response.json()
  cachedToken = { value: json.access_token, expires: now + (json.expires_in ?? 3600) }
  return cachedToken.value
}

function base64Url(bytes: Uint8Array): string {
  let binary = ''
  for (const b of bytes) binary += String.fromCharCode(b)
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}
