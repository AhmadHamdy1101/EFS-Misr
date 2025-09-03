// ال variables الثابتة اللى مش هتتغير خالص فى التطبيق
// زي ال supabase url , supabase api key
import 'package:supabase_flutter/supabase_flutter.dart';

const String supbaseUrl = 'https://cxjgprvhjrjbmrazvrsa.supabase.co';
const String supbaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4amdwcnZoanJqYm1yYXp2cnNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2NjgzOTcsImV4cCI6MjA3MjI0NDM5N30.ff-yCrYmNw0c5Z45fKA-8LEO7DFBGD3TpvXtLAQvyos';
final SupabaseClient supabaseClient = Supabase.instance.client;
