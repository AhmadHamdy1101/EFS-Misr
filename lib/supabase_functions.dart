
import 'dart:convert';
import 'package:efs_misr/constants/constants.dart';

class SupabaseFunctions {

  static Future<String?> createUser({
    required String email,
    required String password,
  }) async {
    final response = await supabaseClient.functions.invoke('add-user',body: {
      "email": email,
      "password": password,
    });

    if (response.status == 200) {
      final data = response.data as Map<String, dynamic>;
      print(data["userId"] as String?);
      return data["userId"] as String?;
    } else {
      print("Error: ${response.data}");
      return null;
    }
  }
}

