import 'package:dartz/dartz.dart';

import '../../../core/Errors/failure.dart';
import '../../../core/entities/user_entity.dart';
import '../../../core/paging/page_query.dart';

/// Fields an admin fills in when creating or editing an account.
class AccountForm {
  const AccountForm({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.companyEmail,
    required this.company,
    required this.positionId,
    required this.role,
    required this.status,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String companyEmail;
  final String company;
  final BigInt? positionId;
  final String role;
  final int status;
}

abstract interface class AccountsRepo {
  Future<Either<Failure, List<UserEntity>>> getUsers(PageQuery query);

  Future<Either<Failure, Unit>> addAccount({
    required AccountForm form,
    required String password,
  });

  Future<Either<Failure, UserEntity>> updateAccount({
    required UserEntity user,
    required AccountForm form,
  });

  Future<Either<Failure, Unit>> deleteAccount({required UserEntity user});

  Future<Either<Failure, List<Map<String, dynamic>>>> getExportRows();
}
