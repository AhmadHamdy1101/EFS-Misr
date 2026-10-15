import { corsHeaders } from '../_shared/cors.ts'
import { errorResponse, HttpError, jsonResponse, requireAdmin } from '../_shared/admin.ts'

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { adminClient } = await requireAdmin(req)

    const { userId, email, password } = await req.json()
    if (!userId) throw new HttpError(400, 'userId is required')

    const updateData: { email?: string; password?: string } = {}
    if (email) updateData.email = email
    if (password) updateData.password = password

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
