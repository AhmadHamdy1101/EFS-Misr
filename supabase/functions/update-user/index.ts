import { corsHeaders } from '../_shared/cors.ts'
import { errorResponse, HttpError, jsonResponse, requireAdmin } from '../_shared/admin.ts'

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { adminClient, callerId } = await requireAdmin(req)

    const { userId, email, password, banned } = await req.json()
    if (!userId) throw new HttpError(400, 'userId is required')

    const updateData: { email?: string; password?: string; ban_duration?: string } = {}
    if (email) updateData.email = email
    if (password) updateData.password = password
    // Terminated/suspended staff: a banned auth user can't sign in or refresh
    // a session, so the account is closed at the server, not just in the UI.
    if (typeof banned === 'boolean') {
      if (banned && userId === callerId) {
        throw new HttpError(400, 'You cannot disable your own account')
      }
      updateData.ban_duration = banned ? '876000h' : 'none'
    }

    if (Object.keys(updateData).length === 0) {
      throw new HttpError(400, 'No data to update')
    }

    const { data, error } = await adminClient.auth.admin.updateUserById(userId, updateData)
    if (error) throw error

    return jsonResponse({ success: true, userId: data.user?.id })
  } catch (error) {
    return errorResponse(error)
  }
})
