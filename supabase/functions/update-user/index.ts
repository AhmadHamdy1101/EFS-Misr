import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req: Request) => {
  // التعامل مع طلبات الـ OPTIONS (CORS)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // استلام البيانات من الـ body
    const { userId, email, password } = await req.json();
    if (!userId) throw new Error('userId is required');

    // تجهيز البيانات اللي هتتحدث
    const updateData: { email?: string; password?: string } = {};
    if (email) updateData.email = email;
    if (password) updateData.password = password;

    if (Object.keys(updateData).length === 0) {
      throw new Error('No data to update');
    }

    // تنفيذ عملية التحديث
    const { data, error } = await supabaseClient.auth.admin.updateUserById(
      userId,
      updateData
    );

    if (error) throw error;

    // نجاح العملية
    return new Response(
      JSON.stringify({ success: true, updatedUser: data }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    // التعامل مع الأخطاء
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
