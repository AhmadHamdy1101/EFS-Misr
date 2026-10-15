import 'package:efs_misr/Features/Accounts/presentation/screens/add_account_page.dart';
import 'package:efs_misr/Features/Accounts/presentation/screens/edit_account_page.dart';
import 'package:efs_misr/Features/Accounts/presentation/controller/accounts_cubit.dart';
import 'package:efs_misr/core/Functions/capitalize_text_function.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_inbut_wedget.dart';

class AccountsPageBody extends StatefulWidget {
  const AccountsPageBody({super.key});

  @override
  State<AccountsPageBody> createState() => _AccountsPageBodyState();
}

class _AccountsPageBodyState extends State<AccountsPageBody> {
  final TextEditingController search = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AccountsCubit>().getAccounts();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<AccountsCubit>().convertAccountsToExcel();
    result.fold(
      (failure) => showAppSnackBar(
        messenger,
        '${'Export failed'.tr}: ${failure.message}',
        isError: true,
      ),
      (status) =>
          showAppSnackBar(messenger, excelExportStatusMessage(status).tr),
    );
  }

  Future<void> _delete(UserEntity user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete'.tr),
        content: Text('${'Delete'.tr} ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<AccountsCubit>().deleteAccount(user);
    result.fold(
      (failure) => showAppSnackBar(messenger, failure.message, isError: true),
      (_) =>
          showAppSnackBar(messenger, 'User ${user.name} deleted successfully'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).buttonTheme.colorScheme?.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        centerTitle: true,
        title: Text(
          'Accounts'.tr,
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AccountsCubit>().getAccounts(),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverToBoxAdapter(
                child: CustomInputWidget(
                  onChanged: (value) {
                    context.read<AccountsCubit>().searchUsers(value);
                    return null;
                  },
                  inbutIcon: 'assets/images/search.svg',
                  inbutHintText: 'Search'.tr,
                  changeToPass: false,
                  textEditingController: search,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  spacing: 10,
                  children: [
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: _export,
                      child: Row(
                        spacing: 10,
                        children: [
                          SvgPicture.asset('assets/images/Excel.svg'),
                          Text(
                            'Export'.tr,
                            style: AppTextStyle.latoBold20(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: () => Get.to(() => const AddAccountPage()),
                      child: Row(
                        spacing: 10,
                        children: [
                          const Icon(Icons.add, color: AppColors.green),
                          Text(
                            'Add Account'.tr,
                            style: AppTextStyle.latoBold20(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<AccountsCubit, AccountsState>(
              builder: (context, state) {
                return switch (state) {
                  GetAccountsLoading() ||
                  AccountsInitial() => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  ),
                  GetAccountsFailed(:final errorMsg) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(errorMsg)),
                  ),
                  GetAccountsSuccess(:final accounts) when accounts.isEmpty =>
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No Accounts'.tr)),
                    ),
                  GetAccountsSuccess(:final accounts) => SliverList.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) => _AccountCard(
                      user: accounts[index],
                      onDelete: () => _delete(accounts[index]),
                    ),
                  ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(int status) => switch (status) {
  1 => 'Active'.tr,
  2 => 'Internship'.tr,
  3 => 'Terminated'.tr,
  4 => 'Suspended'.tr,
  _ => 'Unknown'.tr,
};

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.onDelete});

  final UserEntity user;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final iconColor = ColorFilter.mode(
      Theme.of(context).colorScheme.primary,
      BlendMode.srcIn,
    );

    Widget infoRow(String icon, String text) => Row(
      spacing: 10,
      children: [
        SvgPicture.asset(icon, colorFilter: iconColor),
        Flexible(child: Text(text)),
      ],
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.all(12),
      child: Slidable(
        key: ValueKey(user.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete'.tr,
            ),
          ],
        ),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => Get.to(() => EditAccountPage(user: user)),
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit'.tr,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            spacing: 10,
            children: [
              Row(
                spacing: 15,
                children: [
                  CircleAvatar(
                    radius: size.width * 0.075,
                    backgroundColor: AppColors.lightGreen.withValues(
                      alpha: 0.25,
                    ),
                    backgroundImage: user.image.isNotEmpty
                        ? NetworkImage(user.image)
                        : const AssetImage('assets/images/user.png')
                              as ImageProvider,
                  ),
                  SizedBox(
                    width: size.width * 0.31,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Text(user.name),
                        Text(
                          capitalizeEachWord(
                            user.position?.name ?? 'No Position',
                          ),
                        ),
                        Text(
                          user.company.tr,
                          style: AppTextStyle.latoBold20(
                            context,
                          ).copyWith(color: AppColors.green),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      spacing: 10,
                      children: [
                        Text('Status'.tr),
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.01,
                            horizontal: size.width * 0.04,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff8FCFAD),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            _statusLabel(user.status),
                            style: AppTextStyle.latoBold16(
                              context,
                            ).copyWith(color: AppColors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  infoRow(
                    'assets/images/Phone.svg',
                    user.phone.isEmpty
                        ? capitalizeEachWord('no phone')
                        : user.phone,
                  ),
                  infoRow(
                    'assets/images/address.svg',
                    capitalizeEachWord(user.address),
                  ),
                  infoRow(
                    'assets/images/Email.svg',
                    user.email.isEmpty
                        ? capitalizeEachWord('no email')
                        : user.email,
                  ),
                  infoRow(
                    'assets/images/Email.svg',
                    user.companyEmail.isEmpty
                        ? capitalizeEachWord('no company email')
                        : user.companyEmail,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
