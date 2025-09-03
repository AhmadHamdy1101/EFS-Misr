import 'package:supabase_flutter/supabase_flutter.dart';

abstract class Failure {
  final String message;
  Failure(this.message);

  /// Convert Supabase exceptions into corresponding Failure
  factory Failure.fromException(dynamic exception) {
    if (exception is AuthException) {
      return AuthFailure(exception.message);
    } else if (exception is PostgrestException) {
      return PostgrestFailure(exception.message);
    } else if (exception is StorageException) {
      return StorageFailure(exception.message);
    } else {
      return GeneralFailure('Unexpected error: ${exception.toString()}');
    }
  }
}



class AuthFailure extends Failure {
  AuthFailure(super.message);

  /// Map known Supabase auth error codes to user-friendly messages
  factory AuthFailure.fromSupabaseError(String errorCode) {
    switch (errorCode) {
      case 'invalid_credentials':
        return AuthFailure('Email or Password is incorrect');
      case 'user_already_registered':
        return AuthFailure('User already registered');
      case 'invalid_email':
        return AuthFailure('Email is invalid');
      case 'weak_password':
        return AuthFailure('Password is too weak');
      case 'network_error':
        return AuthFailure('Network error, please try again later');
      default:
        return AuthFailure('Unknown authentication error: $errorCode');
    }
  }
}

class PostgrestFailure extends Failure {
  PostgrestFailure(super.message);
}

/// ---------- Storage Failures ----------
class StorageFailure extends Failure {
  StorageFailure(super.message);
}

class GeneralFailure extends Failure {
  GeneralFailure(super.message);
}