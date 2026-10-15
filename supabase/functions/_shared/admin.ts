import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from './cors.ts'

export class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message)
  }
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status,
  })
}

export function errorResponse(error: unknown): Response {
  const status = error instanceof HttpError ? error.status : 400
  const message = error instanceof Error ? error.message : String(error)
  return jsonResponse({ error: message }, status)
}

/**
 * Verifies the caller is a signed-in Admin and returns a service-role client.
 *
 * The anon key ships inside the APK, so Supabase's default JWT check is not
 * enough: we must resolve the real user from the bearer token and look up
 * their role in `public.users` before doing anything privileged.
 */
export async function requireAdmin(req: Request): Promise<{
  adminClient: SupabaseClient
  callerId: string
}> {
  const authHeader = req.headers.get('Authorization') ?? ''
  const token = authHeader.replace(/^Bearer\s+/i, '')
  if (!token) throw new HttpError(401, 'Missing Authorization header')

  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { persistSession: false, autoRefreshToken: false } },
  )

  // getUser rejects the anon key (it has no `sub`), so only real sessions pass.
  const { data: userData, error: userError } = await adminClient.auth.getUser(token)
  if (userError || !userData?.user) throw new HttpError(401, 'Invalid session')

  const callerId = userData.user.id
  const { data: profile, error: profileError } = await adminClient
    .from('users')
    .select('role')
    .eq('userid', callerId)
    .maybeSingle()

  if (profileError) throw new HttpError(500, profileError.message)
  if (profile?.role !== 'Admin') throw new HttpError(403, 'Admins only')

  return { adminClient, callerId }
}
