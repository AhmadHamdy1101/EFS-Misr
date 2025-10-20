import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_cubit.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class EditAssetsPageBody extends StatefulWidget {
  const EditAssetsPageBody({super.key, this.assets});
  final Assets? assets;

  @override
  State<EditAssetsPageBody> createState() => _EditAssetsPageBodyState();
}

class _EditAssetsPageBodyState extends State<EditAssetsPageBody> {
  String? selectedValue;
  final selectedBranchValue = BigInt.zero.obs;
  final selectedTypeValue = ''.obs;

  final addAccountLoading = false.obs;
  final typeData = [
    {'name': 'Furniture', 'value': 'Furniture'},
    {'name': 'Electricity', 'value': 'Electricity'},
    {'name': 'air conditioning', 'value': 'air conditioning'},
    {'name': 'Digital Call', 'value': 'Digital Call'},
  ];

  final branchData = <Map<String, dynamic>>[].obs;

  Future<void> loadBranch() async {
    final brnachData = await supabaseClient.branch.select();
    branchData.value = brnachData.map<Map<String, dynamic>>((po) {
      return {"name": po["name"], "value": po["id"].toString()};
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadBranch();
  }

  final TextEditingController barcode = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController floor = TextEditingController();
  final TextEditingController place = TextEditingController();
  final TextEditingController branch = TextEditingController();
  final TextEditingController type = TextEditingController();

  final typeTxt = ''.obs;
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
              'Edit Assets'.tr,
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
                            inbutHintText: '${widget.assets?.barcode}',
                            changeToPass: false,
                            textEditingController: barcode,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Password.svg',
                            inbutHintText: '${widget.assets?.name}',
                            changeToPass: false,
                            textEditingController: name,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Email.svg',
                            inbutHintText: '${widget.assets?.floor}',
                            changeToPass: false,
                            textEditingController: floor,
                          ),
                          CustomInputWidget(
                            inbutIcon: 'assets/images/Email.svg',
                            inbutHintText: '${widget.assets?.place}',
                            changeToPass: false,
                            textEditingController: place,
                          ),

                          Obx(() {
                            return CustomDropdownWidget(
                              inbutIcon: 'assets/images/address.svg',
                              inbutHintText: '${widget.assets?.branchObject?.name}',
                              textEditingController: branch,
                              selectedValue: selectedValue,
                              Data: branchData.toList(),
                              onChanged: (value) {
                                selectedBranchValue.value = BigInt.tryParse(
                                  value!,
                                )!;
                              },
                            );
                          }),
                          CustomDropdownWidget(
                            inbutIcon: 'assets/images/company.svg',
                            inbutHintText: '${widget.assets?.type}',
                            selectedValue: selectedValue,
                            onChanged: (value) {
                              typeTxt.value = value!;
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
                      onPressed: () async {
                        // addAccountLoading.value = true;
                        // await context.read<AssetsCubit>().addAssetsData(
                        //   barcode: barcode.text,
                        //   name: name.text,
                        //   floor: floor.text,
                        //   place: place.text,
                        //   type: typeTxt.value,
                        //   branch: selectedBranchValue.value,
                        // );
                        // addAccountLoading.value = false;
                      },
                      child: Obx(() {
                        return addAccountLoading.value
                            ? CircularProgressIndicator(color: AppColors.white)
                            : Text(
                                'Add',
                                style: AppTextStyle.latoBold26(context),
                              );
                      }),
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
