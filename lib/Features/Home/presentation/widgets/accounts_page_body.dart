import 'package:efs_misr/Features/Home/presentation/pages/add_account_page.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/accounts_cubit.dart';
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
  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  String checkStatus(int? status) {
    switch (status) {
      case 1:
        return 'Active';
      case 2:
        return 'Internship';
      case 3:
        return 'Terminated';
      case 4:
        return 'Suspended';
      default:
        return 'Unknown';
    }
  }

  Future<void> loadAccounts() async {
    await context.read<AccountsCubit>().getAccounts();
  }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(),
        centerTitle: true,
        title: Text(
          'Accounts'.tr,
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.8,
              child: Form(
                key: formKey,
                child: Column(
                  spacing: 40,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CustomInputWidget(
                        onChanged: (value) {
                          return context.read<AccountsCubit>().searchTickets(
                            value,
                          );
                        },
                        inbutIcon: 'assets/images/search.svg',
                        inbutHintText: 'Search'.tr,
                        changeToPass: false,
                        textEditingController: search,
                      ),
                    ),
                    SizedBox(height: 1),
                  ],
                ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).buttonTheme.colorScheme?.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      context.read<AccountsCubit>().convertAccountsToExcel();
                    },
                    child: Row(
                      spacing: 10,
                      children: [
                        SvgPicture.asset('assets/images/Excel.svg'),
                        Text(
                          'Export',
                          style: AppTextStyle.latoBold20(
                            context,
                          ).copyWith(color: AppColors.green),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).buttonTheme.colorScheme?.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      Get.to(() => AddAccountPage());
                    },
                    child: Row(
                      spacing: 10,
                      children: [
                        Icon(Icons.add, color: AppColors.green),
                        Text(
                          'Add Account',
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
          SliverFillRemaining(
            child: BlocBuilder<AccountsCubit, AccountsState>(
              builder: (context, state) {
                if (state is GetAccountsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }
                if (state is GetAccountsFailed) {
                  return Center(child: Text(state.errorMsg));
                }
                if (state is GetAccountsSuccess) {
                  final users = state.accounts;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {},
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.all(12),
                          child: Slidable(
                            key: ValueKey(users[index].id), // لازم key فريد
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),

                              children: [
                                SlidableAction(
                                  onPressed: (context) async {
                                    context.read<AccountsCubit>().deleteAccount(
                                      users[index].id,
                                      users[index].userid,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${users[index].name} تم حذفه',
                                        ),
                                      ),
                                    );
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete'.tr,
                                ),
                              ],
                            ),

                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 20,
                              ),

                              child: Row(
                                spacing: 15,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: screenWidth * 0.15,
                                    height: screenWidth * 0.15,
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreen.withOpacity(
                                        0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(60),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.black.withAlpha(25),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ClipRRect(
                                      child: Image.asset(
                                        width: screenWidth,
                                        'assets/images/user.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: screenWidth * 0.3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("${users[index].name}".tr),
                                            Text(
                                              users[index].position?.name ??
                                                  "No Position",
                                            ),
                                          ],
                                        ),
                                        Text(
                                          (users[index].company ?? '').tr,
                                          style: AppTextStyle.latoRegular16(
                                            context,
                                          ).copyWith(color: AppColors.green),
                                        ),
                                        Text(
                                          (users[index].email ?? '').tr,
                                          style:
                                              AppTextStyle.latoRegular16(
                                                context,
                                              ).copyWith(
                                                color: AppColors.gray,
                                                overflow: TextOverflow.clip,
                                              ),
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
                                            vertical: screenHeight * 0.01,
                                            horizontal: screenWidth * 0.04,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xff8FCFAD),
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                          child: Row(
                                            spacing: 4,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                checkStatus(
                                                  users[index].status,
                                                ).tr,
                                                style:
                                                    AppTextStyle.latoBold16(
                                                      context,
                                                    ).copyWith(
                                                      color: AppColors.white,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return Text('No Accounts');
              },
            ),
          ),
        ],
      ),
    );
  }
}
