import { corsHeaders } from '../_shared/cors.ts'
import { errorResponse, HttpError, jsonResponse, requireAdmin } from '../_shared/admin.ts'

// Columns an admin may set on a new profile row. Anything else in the body is ignored.
const PROFILE_FIELDS = [
  'name', 'phone', 'address', 'positions', 'role', 'status', 'company_email', 'Company',
] as const

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { adminClient } = await requireAdmin(req)

    const { email, password, profile } = await req.json()
    if (!email || !password) throw new HttpError(400, 'email and password are required')

    const { data, error } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    })
    if (error) throw error
    const userId = data.user!.id

    // Create the auth user and its profile row together. If the row fails,
    // remove the auth user so no half-created account is left behind.
    if (profile) {
      const row: Record<string, unknown> = { userid: userId, email }
      for (const field of PROFILE_FIELDS) {
        if (profile[field] !== undefined) row[field] = profile[field]
      }
      const { error: insertError } = await adminClient.from('users').insert(row)
      if (insertError) {
        await adminClient.auth.admin.deleteUser(userId)
        throw insertError
      }
    }

    return jsonResponse({ userId })
  } catch (error) {
    return errorResponse(error)
  }
})
