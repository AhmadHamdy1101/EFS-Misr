import 'dart:developer' as developer;

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
      // Codes, details and hints are database internals: log them for
      // debugging, show the user only a readable message.
      developer.log(
        'PostgREST error ${exception.code}: ${exception.message} '
        '(details: ${exception.details}, hint: ${exception.hint})',
        name: 'Failure',
      );
      return PostgrestFailure(_postgrestMessage(exception));
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

String _postgrestMessage(PostgrestException exception) {
  final message = exception.message.trim();
  switch (exception.code) {
    // Raised on purpose by our database functions (RAISE EXCEPTION ...):
    // their message is written for the user.
    case 'P0001':
      return message.isEmpty ? 'The request was rejected.' : message;
    case '42501': // insufficient_privilege / row-level security
      return "You don't have permission to do this.";
    case '23505': // unique_violation
      return 'This record already exists.';
    case '23503': // foreign_key_violation
      return 'This item is linked to something that no longer exists.';
    case 'PGRST116': // .single() found no row
      return 'The item was not found or you no longer have access to it.';
  }
  return message.isEmpty ? 'The request failed. Please try again.' : message;
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
