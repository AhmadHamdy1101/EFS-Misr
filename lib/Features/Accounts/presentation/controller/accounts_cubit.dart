import 'dart:developer';

import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../core/models/supadart_header.dart';
import '../../../../core/models/user.dart';

part 'accounts_state.dart';

class AccountsCubit extends Cubit<AccountsState> {
  HomeRepo homeRepo;
  AccountsCubit(this.homeRepo) : super(AccountsInitial());

  final List<Users> allUsers = [];
  final List<Users> searchedUSers = [];

  Future<void> getAccounts() async {
    emit(GetAccountsLoading());
    final result = await homeRepo.getUsers();
    result.fold(
      (failure) {
        emit(GetAccountsFailed(failure.message));
      },
      (accounts) {
        allUsers.clear();
        allUsers.addAll(accounts);
        emit(GetAccountsSuccess(allUsers));
      },
    );
  }

  searchUsers(String? search) {
    final query = search?.trim().toLowerCase() ?? '';
    if (query.isEmpty) {
      emit(GetAccountsSuccess(allUsers));
      return;
    }
    searchedUSers.clear();
    final res = allUsers.where((user) {
      final nameMatch = user.name?.toLowerCase().contains(query) ?? false;
      final emailMatch = user.email?.toLowerCase().contains(query) ?? false;
      final companyMatch = user.company?.toLowerCase().contains(query) ?? false;
      return nameMatch || emailMatch || companyMatch;
    }).toList();
    searchedUSers.addAll(res);
    emit(GetAccountsSuccess(searchedUSers));
  }

  Future<ExcelExportStatus> convertAccountsToExcel() async {
    // Never include the password column in an exported employee list.
    final data = await supabaseClient.users.select(
      'id,name,email,phone,address,role,status,created_at,company_email,Company',
    );
    if (data.isEmpty) return ExcelExportStatus.noData;

    return saveRowsToExcel(
      data.map((row) => Map<String, dynamic>.from(row)).toList(),
      fileNamePrefix: 'Users',
    );
  }

  Future<void> deleteAccount(
    BigInt id,
    String? userid,
    String? username,
  ) async {
    try {
      await supabaseClient.users.delete().eq('id', id);

      await supabaseClient.functions.invoke(
        'delete-user',
        body: {'userId': userid},
      );
      await getAccounts();
      Get.snackbar("Delete Success", 'User $username deleted successfully');
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> updateUserData({
    required String userID,
    required String? userName,
    required String? phone,
    required String? address,
    required BigInt? position,
    required int? status,
    required String? role,
    required String? companyEmail,
    required String? company,
    required String? email,
    required String? password,
  }) async {
    final res = await homeRepo.updateUserData(
      userID: userID,
      userName: userName,
      phone: phone,
      address: address,
      position: position,
      status: status,
      role: role,
      companyEmail: companyEmail,
      company: company,
      email: email,
      password: password,
    );
    await res.fold<Future<void>>(
      (l) async {
        Get.snackbar(
          "Error while updating",
          l.message,
          backgroundColor: Colors.red,
          colorText: AppColors.white,
        );
      },
      (r) async {
        Get.snackbar(
          "Update user successful",
          'User has successfully updated',
          backgroundColor: AppColors.green,
          colorText: AppColors.white,
        );
        await getAccounts();
      },
    );
  }
}
