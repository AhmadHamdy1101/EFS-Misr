import 'package:efs_misr/Features/Accounts/presentation/controller/accounts_cubit.dart';
import 'package:efs_misr/Features/Accounts/presentation/screens/add_success_page.dart';
import 'package:efs_misr/Features/Accounts/presentation/widgets/account_form_body.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class AddAccountPage extends StatelessWidget {
  const AddAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountFormBody(
      title: 'Add Accounts',
      submitLabel: 'Add',
      onSubmit: (form, password) async {
        final messenger = ScaffoldMessenger.of(context);
        final result = await context.read<AccountsCubit>().addAccount(
          form: form,
          password: password,
        );
        result.fold(
          (failure) =>
              showAppSnackBar(messenger, failure.message, isError: true),
          (_) => Get.off(
            () => AddSuccessPage(
              message: 'Account created successfully',
              buttonTitle: 'Add Another Account',
              onPress: () => Get.off(() => const AddAccountPage()),
              secondPress: Get.back,
            ),
          ),
        );
      },
    );
  }
}
