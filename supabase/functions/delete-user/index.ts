import { corsHeaders } from '../_shared/cors.ts'
import { errorResponse, HttpError, jsonResponse, requireAdmin } from '../_shared/admin.ts'

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { adminClient, callerId } = await requireAdmin(req)

    const { userId } = await req.json()
    if (!userId) throw new HttpError(400, 'userId is required')
    if (userId === callerId) throw new HttpError(400, 'You cannot delete your own account')

    // Delete the auth user first: if that fails nothing has changed. Then remove
    // the profile row so the two never drift apart.
    const { error: authError } = await adminClient.auth.admin.deleteUser(userId)
    if (authError) throw authError

    const { error: rowError } = await adminClient.from('users').delete().eq('userid', userId)
    if (rowError) throw rowError

    return jsonResponse({ success: true, deletedUserId: userId })
  } catch (error) {
    return errorResponse(error)
  }
})
