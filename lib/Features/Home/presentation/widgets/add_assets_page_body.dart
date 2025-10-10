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

class AddAssetsPageBody extends StatefulWidget {
  const AddAssetsPageBody({super.key});

  @override
  State<AddAssetsPageBody> createState() => _AddAssetsPageBodyState();
}

class _AddAssetsPageBodyState extends State<AddAssetsPageBody> {
  String? selectedValue;
  final selectedbranchValue = BigInt.zero.obs;
  final selectedStatusValue = 0.obs;
  final selectedUserStatusValue = 0.obs;
  final addAccountLoading = false.obs;
  final company = [
    {'name': 'EFS', 'value': 'EFS'},
    {'name': 'Bank Misr', 'value': 'Bank Misr'},
  ];
  final typeData = [
    {'name': 'Furniture', 'value': 'Furniture'},
    {'name': 'Electricity', 'value': 'Electricity'},
    {'name': 'air conditioning', 'value': 'air conditioning'},
    {'name': 'Digital Call', 'value': 'Digital Call'},


  ];
  final status = [
    {'name': 'Active', 'value': '1'},
    {'name': 'Internship', 'value': '2'},
    {'name': 'Terminated', 'value': '3'},
    {'name': 'Suspended', 'value': '4'},
  ];
  final brnchRes = <Map<String, dynamic>>[].obs;

  Future<void> loadbrnach() async {
    final brnachData = await supabaseClient.branch.select();
    brnchRes.value = brnachData.map<Map<String, dynamic>>((po) {
      return {"name": po["name"], "value": po["id"].toString()};
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadbrnach();
  }

  final TextEditingController barcode = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController floor = TextEditingController();
  final TextEditingController place = TextEditingController();
  final TextEditingController Branch = TextEditingController();
  final TextEditingController type = TextEditingController();

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
              'Add Assets'.tr,
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
                            inbutHintText: 'Barcode'.tr,
                            changeToPass: false,
                            textEditingController: barcode,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Password.svg',
                            inbutHintText: 'Name'.tr,
                            changeToPass: false,
                            textEditingController: name,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Email.svg',
                            inbutHintText: 'Floor'.tr,
                            changeToPass: false,
                            textEditingController: floor,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Email.svg',
                            inbutHintText: 'Place'.tr,
                            changeToPass: false,
                            textEditingController: place,
                          ),

                          Obx(() {
                            return CustomDropdownWidget(
                              inbutIcon: 'assets/images/address.svg',
                              inbutHintText: 'Branch'.tr,
                              textEditingController: Branch,
                              selectedValue: selectedValue,
                              Data: brnchRes.toList(),
                              onChanged: (value) {
                                selectedbranchValue.value = BigInt.tryParse(
                                  value!,
                                )!;
                              },
                            );
                          }),
                          CustomDropdownWidget(
                            inbutIcon: 'assets/images/company.svg',
                            inbutHintText: 'Type'.tr,
                            selectedValue: selectedValue,
                            onChanged: (value) {
                              companyTxt.value = value!;
                            },
                            Data: typeData,
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
                        // context.read<AuthCubit>().addAccount(
                        //   email: email.text,
                        //   userName: username.text,
                        //   password: password.text,
                        //   phone: phone.text,
                        //   address: address.text,
                        //   companyEmail: companyEmail.text,
                        //   company: companyTxt.value,
                        //   position: selectedPositionValue.value,
                        //   role: roleTxt.value,
                        //   status: selectedStatusValue.value,
                        // );
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
