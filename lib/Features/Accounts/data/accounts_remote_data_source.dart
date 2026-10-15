import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/Errors/failure.dart';

import '../../../core/models/supadart_header.dart';
import '../../../core/models/user.dart';
import '../../../core/paging/page_query.dart';
import '../domain/accounts_repo.dart';

abstract interface class AccountsRemoteDataSource {
  Future<List<Users>> getUsers(PageQuery query);
  Future<void> addAccount({
    required AccountForm form,
    required String password,
  });
  Future<Users> updateAccount({
    required String userId,
    required bool emailChanged,
    required AccountForm form,
  });
  Future<void> deleteAccount({required String userId});
  Future<List<Map<String, dynamic>>> getExportRows();
}

class AccountsRemoteDataSourceImpl implements AccountsRemoteDataSource {
  AccountsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Users>> getUsers(PageQuery query) {
    var request = _client.users.select(Users.selectColumns);
    if (query.hasSearch) {
      request = request.or(
        ilikeAny([Users.c_name, Users.c_email, Users.c_company], query.search),
      );
    }
    return request
        .order(Users.c_name)
        .order(Users.c_id)
        .range(query.from, query.to)
        .withConverter(Users.converter);
  }

  @override
  Future<void> addAccount({
    required AccountForm form,
    required String password,
  }) async {
    // The edge function creates the auth user and the profile row together
    // and rolls back the auth user if the row can't be written.
    await _invoke('add-user', {
      'email': form.email,
      'password': password,
      'profile': {
        'name': form.name,
        'phone': form.phone,
        'address': form.address,
        'company_email': form.companyEmail,
        'Company': form.company,
        'role': form.role,
        'status': form.status,
        if (form.positionId != null) 'positions': form.positionId.toString(),
      },
    });
  }

  @override
  Future<Users> updateAccount({
    required String userId,
    required bool emailChanged,
    required AccountForm form,
  }) async {
    if (emailChanged) {
      await _invoke('update-user', {'userId': userId, 'email': form.email});
    }
    return _client.users
        .update(
          Users.update(
            name: form.name,
            email: form.email,
            phone: form.phone,
            address: form.address,
            companyEmail: form.companyEmail,
            company: form.company,
            positionID: form.positionId,
            role: form.role,
            status: form.status,
          ),
        )
        .eq(Users.c_userid, userId)
        .select(Users.selectColumns)
        .single()
        .withConverter(Users.converterSingle);
  }

  @override
  Future<void> deleteAccount({required String userId}) async {
    // The edge function deletes the auth user and then the profile row.
    await _invoke('delete-user', {'userId': userId});
  }

  @override
  Future<List<Map<String, dynamic>>> getExportRows() async {
    final rows = await _client.users.select(
      'id,name,email,phone,address,role,status,created_at,company_email,Company',
    );
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> _invoke(String function, Map<String, dynamic> body) async {
    try {
      await _client.functions.invoke(function, body: body);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['error']?.toString() : null;
      throw GeneralFailure(message ?? e.reasonPhrase ?? 'Request failed');
    }
  }
}
