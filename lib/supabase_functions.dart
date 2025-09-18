
import 'package:efs_misr/constants/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFunctions {

  static Future<String?> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'add-user',
        body: {
          "email": email,
          "password": password,
        },
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        return data["userId"] as String?;
      } else {

        final errorData = response.data;
        if (errorData is FunctionException) {
          return errorData.details['error'];
        } else {
          return "Unknown error";
        }
      }
    } on FunctionException catch (e) {
      return e.details['error'];
    }
  }
}

