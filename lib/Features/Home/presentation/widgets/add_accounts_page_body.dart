import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class AddAccountPageBody extends StatefulWidget {
  const AddAccountPageBody({super.key});

  @override
  State<AddAccountPageBody> createState() => _AddAccountPageBodyState();
}

class _AddAccountPageBodyState extends State<AddAccountPageBody> {
  String? selectedValue;
  final selectedPositionValue = BigInt.zero.obs;
  final selectedStatusValue = 0.obs;
  final selectedUserStatusValue = 0.obs;
  final addAccountLoading = false.obs;
  final company = [
    {'name': 'EFS', 'value': 'EFS'},
    {'name': 'Bank Misr', 'value': 'Bank Misr'},
  ];
  final role = [
    {'name': 'Admin', 'value': 'Admin'},
    {'name': 'User', 'value': 'User'},
  ];
  final status = [
    {'name': 'Active', 'value': '1'},
    {'name': 'Internship', 'value': '2'},
    {'name': 'Terminated', 'value': '3'},
    {'name': 'Suspended', 'value': '4'},
  ];
  final positions = <Map<String, dynamic>>[].obs;

  Future<void> loadPositions() async {
    final positionsData = await supabaseClient.positions.select();
    positions.value = positionsData.map<Map<String, dynamic>>((po) {
      return {"name": po["name"], "value": po["id"].toString()};
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadPositions();
  }

  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController companyEmail = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController Status = TextEditingController();
  final TextEditingController Postition = TextEditingController();
  final companyTxt = ''.obs;
  final roleTxt = ''.obs;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            centerTitle: true,
            leading: BackButton(color: Theme.of(context).colorScheme.primary),
            title: Text(
              'Add Accounts'.tr,
              style: AppTextStyle.latoBold26(
                context,
              ).copyWith(color: AppColors.green),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                spacing: 20,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        spacing: 15,
                        children: [
                          CustomInputWidget(
                            inbutIcon: 'assets/images/profile.svg',
                            inbutHintText: 'Username'.tr,
                            changeToPass: false,
                            textEditingController: username,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Password.svg',
                            inbutHintText: 'Password'.tr,
                            changeToPass: false,
                            textEditingController: password,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Email.svg',
                            inbutHintText: 'Email'.tr,
                            changeToPass: false,
                            textEditingController: email,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Email.svg',
                            inbutHintText: 'Company Email'.tr,
                            changeToPass: false,
                            textEditingController: companyEmail,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/address.svg',
                            inbutHintText: 'Address'.tr,
                            changeToPass: false,
                            textEditingController: address,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Phone.svg',
                            inbutHintText: 'Phone'.tr,
                            changeToPass: false,
                            textEditingController: phone,
                          ),
                          CustomDropdownWidget(
                            inbutIcon: 'assets/images/status.svg',
                            inbutHintText: 'Status'.tr,
                            textEditingController: Status,
                            selectedValue: selectedValue,
                            Data: status,
                            onChanged: (value) {
                              selectedStatusValue.value = int.tryParse(value!)!;
                            },
                          ),
                          Obx(() {
                            return CustomDropdownWidget(
                              inbutIcon: 'assets/images/position.svg',
                              inbutHintText: 'Position'.tr,
                              textEditingController: Postition,
                              selectedValue: selectedValue,
                              Data: positions.toList(),
                              onChanged: (value) {
                                selectedPositionValue.value = BigInt.tryParse(
                                  value!,
                                )!;
                              },
                            );
                          }),
                          CustomDropdownWidget(
                            inbutIcon: 'assets/images/company.svg',
                            inbutHintText: 'Company'.tr,
                            selectedValue: selectedValue,
                            onChanged: (value) {
                              companyTxt.value = value!;
                            },
                            Data: company,
                          ),
                          CustomDropdownWidget(
                            inbutIcon: 'assets/images/role.svg',
                            inbutHintText: 'Role'.tr,
                            selectedValue: selectedValue,
                            onChanged: (value) {
                              roleTxt.value = value!;
                            },
                            Data: role,
                            iconColor: AppColors.gray,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: screenWidth,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 10),
                        ),
                        backgroundColor: WidgetStatePropertyAll(
                          AppColors.green,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          AppColors.white,
                        ),
                      ),
                      onPressed: () {
                        addAccountLoading.value = true;
                        context.read<AuthCubit>().addAccount(
                          email: email.text,
                          userName: username.text,
                          password: password.text,
                          phone: phone.text,
                          address: address.text,
                          companyEmail: companyEmail.text,
                          company: companyTxt.value,
                          position: selectedPositionValue.value,
                          role: roleTxt.value,
                          status: selectedStatusValue.value,
                        );
                        addAccountLoading.value = false;
                      },
                      child: Obx(
                        () => addAccountLoading.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Add',
                                style: AppTextStyle.latoBold26(context),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
