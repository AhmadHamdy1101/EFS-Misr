import 'package:supabase_flutter/supabase_flutter.dart';

abstract class Failure {
  final String message;
  Failure(this.message);

  factory Failure.fromException(dynamic exception) {
    if (exception is Failure) {
      return exception;
    }

    if (exception is AuthException) {
      // استعمل الكود من Supabase لو موجود
      return AuthFailure.fromSupabaseError(exception.code ?? 'unknown');
    } else if (exception is PostgrestException) {
      final details = <String>[];
      final message = exception.message.trim();
      if (message.isNotEmpty) details.add(message);
      if (exception.code?.trim().isNotEmpty ?? false) {
        details.add('Code: ${exception.code}');
      }
      final exceptionDetails = exception.details?.toString().trim() ?? '';
      if (exceptionDetails.isNotEmpty && exceptionDetails != 'null') {
        details.add('Details: $exceptionDetails');
      }
      final hint = exception.hint?.trim() ?? '';
      if (hint.isNotEmpty) details.add('Hint: $hint');

      return PostgrestFailure(
        details.isEmpty
            ? 'The database rejected the request without an error message.'
            : details.join('\n'),
      );
    } else if (exception is StorageException) {
      final message = exception.message.trim();
      return StorageFailure(
        message.isEmpty ? 'The file storage request failed.' : message,
      );
    } else {
      final message = exception.toString().trim();
      return GeneralFailure(
        message.isEmpty
            ? 'An unexpected error occurred.'
            : 'Unexpected error: $message',
      );
    }
  }
}

class AuthFailure extends Failure {
  AuthFailure(super.message);

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

class StorageFailure extends Failure {
  StorageFailure(super.message);
}

class GeneralFailure extends Failure {
  GeneralFailure(super.message);
}
