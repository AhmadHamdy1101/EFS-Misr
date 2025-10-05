import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/data/models/user.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/accounts_cubit.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class EditAccountPageBody extends StatefulWidget {
  const EditAccountPageBody({super.key, this.user});

  final Users? user;

  @override
  State<EditAccountPageBody> createState() => _EditAccountPageBodyState();
}

class _EditAccountPageBodyState extends State<EditAccountPageBody> {
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
    // TODO: implement initState
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
              'Edit Accounts'.tr,
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
                            inbutHintText: '${widget.user?.name}',
                            changeToPass: false,
                            textEditingController: username,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Password.svg',
                            inbutHintText: '${widget.user?.password}',
                            changeToPass: false,
                            textEditingController: password,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Email.svg',
                            inbutHintText: '${widget.user?.email}',
                            changeToPass: false,
                            textEditingController: email,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Email.svg',
                            inbutHintText: '${widget.user?.companyEmail}',
                            changeToPass: false,
                            textEditingController: companyEmail,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/address.svg',
                            inbutHintText: '${widget.user?.address}',
                            changeToPass: false,
                            textEditingController: address,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Phone.svg',
                            inbutHintText: '${widget.user?.phone}',
                            changeToPass: false,
                            textEditingController: phone,
                          ),
                          CustomDropdownWidget(
                            inbutIcon: 'assets/images/status.svg',
                            inbutHintText: widget.user?.status == '1'
                                ? 'Active'
                                : widget.user?.status == '2'
                                ? 'Internship'
                                : widget.user?.status == '3'
                                ? 'Terminated'
                                : 'Suspended',
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
                              inbutHintText: '${widget.user?.position?.name}',
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
                            inbutHintText: '${widget.user?.company}',
                            selectedValue: selectedValue,
                            onChanged: (value) {
                              companyTxt.value = value!;
                            },
                            Data: company,
                          ),
                          CustomDropdownWidget(
                            inbutIcon: 'assets/images/role.svg',
                            inbutHintText: '${widget.user?.role}',
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
                        context.read<AccountsCubit>().updateUserData(
                          userID: widget.user!.userid!,
                          userName: username.text.isEmpty
                              ? widget.user!.name ?? ''
                              : username.text,
                          phone: phone.text.isEmpty
                              ? widget.user!.phone ?? ''
                              : phone.text,
                          address: address.text.isEmpty
                              ? widget.user!.address ?? ''
                              : address.text,
                          position: selectedPositionValue.value == BigInt.zero
                              ? widget.user!.position!.id
                              : selectedPositionValue.value,
                          status: selectedStatusValue.value == 0
                              ? widget.user!.status
                              : selectedStatusValue.value,
                          role: roleTxt.value.isEmpty
                              ? widget.user!.role ?? ''
                              : roleTxt.value,
                          companyEmail: companyEmail.text.isEmpty
                              ? widget.user!.companyEmail ?? ''
                              : companyEmail.text,
                          company: companyTxt.value.isEmpty
                              ? widget.user!.company ?? ''
                              : companyTxt.value,
                          email: email.text.isEmpty
                              ? widget.user!.email ?? ''
                              : email.text,
                          password: password.text.isEmpty
                              ? widget.user!.password ?? ''
                              : password.text,
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
                                'Edit',
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
