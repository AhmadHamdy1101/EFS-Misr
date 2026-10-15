import 'package:efs_misr/Features/Accounts/presentation/controller/accounts_cubit.dart';
import 'package:efs_misr/Features/Accounts/presentation/widgets/account_form_body.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/entities/user_entity.dart';

class EditAccountPage extends StatelessWidget {
  const EditAccountPage({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return AccountFormBody(
      title: 'Edit Accounts',
      submitLabel: 'Edit',
      user: user,
      onSubmit: (form, _) async {
        final messenger = ScaffoldMessenger.of(context);
        final result = await context.read<AccountsCubit>().updateAccount(
          user: user,
          form: form,
        );
        result.fold(
          (failure) =>
              showAppSnackBar(messenger, failure.message, isError: true),
          (_) {
            Get.back();
            showAppSnackBar(messenger, 'User has successfully updated'.tr);
          },
        );
      },
    );
  }
}
