import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

serve(async (req) => {
     if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
      }
  try {
    // نعمل client باستخدام auth context للـ user اللي عمل request
    const supabaseClient = createClient(
      supabaseUrl,
      anonKey,
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const { email, password } = await req.json();

    // هنا نستخدم service_role key بس جوه الفانكشن لإنشاء user جديد في Auth
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: user, error } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 400 });
    }

    const userId = user.user?.id;
    return new Response(JSON.stringify({ userId }), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});
