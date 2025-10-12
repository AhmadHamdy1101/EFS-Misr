import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/presentation/pages/add_assets_page.dart';
import 'package:efs_misr/Features/Home/presentation/pages/assets_details_page.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_repair_cubit.dart';
import 'package:efs_misr/core/utils/widgets/custom_outline_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_button_widget.dart';
import '../../../../core/utils/widgets/custom_dropdown_widget.dart';
import '../../../../core/utils/widgets/custom_inbut_wedget.dart';
import '../viewmodel/assets_tickets_cubit.dart';

class AssetsPageBody extends StatefulWidget {
  const AssetsPageBody({super.key});

  @override
  State<AssetsPageBody> createState() => _AssetsPageBodyState();
}

class _AssetsPageBodyState extends State<AssetsPageBody> {
  final selectedArea = Rxn<BigInt>();
  final selectedBranch = Rxn<BigInt>();

  String? selectedValue;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController search = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController branchController = TextEditingController();

  final areaRes = <Map<String, dynamic>>[].obs;

  Future<void> loadArea() async {
    final areaData = await supabaseClient.area.select();
    areaRes.value = areaData.map<Map<String, dynamic>>((po) {
      return {"name": po["name"], "value": po["id"].toString()};
    }).toList();
  }

  final branchRes = <Map<String, dynamic>>[].obs;

  Future<void> loadBranch() async {
    final branchData = await supabaseClient.branch.select();
    branchRes.value = branchData.map<Map<String, dynamic>>((po) {
      return {"name": po["name"], "value": po["id"].toString()};
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadArea();
    loadBranch();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(),
        centerTitle: true,
        title: Text(
          'Assets'.tr,
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: BlocBuilder<AssetsCubit, AssetsState>(
        buildWhen: (previous, current) =>
            current is GetAssetsLoading ||
            current is GetAssetsSuccess ||
            current is GetAssetsFailure,
        builder: (context, state) {
          if (state is GetAssetsLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.green),
            );
          } else if (state is GetAssetsSuccess) {
            final assets = state.assets;
            return CustomScrollView(
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
                              onChanged: (search) {
                                return context.read<AssetsCubit>().searchAssets(
                                  search,
                                );
                              },
                              inbutIcon: 'assets/images/search.svg',
                              inbutHintText: 'Search'.tr,
                              changeToPass: false,
                              textEditingController: search,
                              textInputType: TextInputType.emailAddress,
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
                            context.read<AssetsCubit>().convertAssetsToExcel();
                          },
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).buttonTheme.colorScheme?.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          onPressed: () {
                            Get.to(AddAssetsPage());
                          },
                          child: Row(
                            spacing: 10,
                            children: [
                              Icon(Icons.add, color: AppColors.green),
                              Text(
                                'Add Assets'.tr,
                                style: AppTextStyle.latoBold20(
                                  context,
                                ).copyWith(color: AppColors.green),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return Container(
                                    padding: EdgeInsets.only(
                                      top: 30,
                                      right: 10,
                                      left: 10,
                                    ),
                                    child: Column(
                                      spacing: 10,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Filter",
                                          style: AppTextStyle.latoBold26(
                                            context,
                                          ).copyWith(color: AppColors.green),
                                        ),
                                        Column(
                                          spacing: 10,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Area',
                                              style: AppTextStyle.latoBold20(
                                                context,
                                              ),
                                            ),
                                            CustomDropdownWidget(
                                              inbutIcon:
                                                  'assets/images/address.svg',
                                              inbutHintText: 'Area',
                                              textEditingController:
                                                  areaController,
                                              selectedValue: selectedArea.value
                                                  ?.toString(),
                                              onChanged: (value) {
                                                selectedArea.value =
                                                    BigInt.tryParse(value!);
                                              },
                                              Data: areaRes.isNotEmpty
                                                  ? areaRes.toList()
                                                  : [],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          spacing: 10,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Branch',
                                              style: AppTextStyle.latoBold20(
                                                context,
                                              ),
                                            ),
                                            CustomDropdownWidget(
                                              textEditingController:
                                                  branchController,
                                              inbutIcon:
                                                  'assets/images/address.svg',
                                              inbutHintText: 'Branch',
                                              selectedValue: selectedBranch
                                                  .value
                                                  ?.toString(),
                                              Data: branchRes.toList(),
                                              onChanged: (value) {
                                                selectedBranch.value =
                                                    BigInt.tryParse(value!);
                                              },
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        SizedBox(
                                          width: screenWidth,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,

                                            children: [
                                              SizedBox(
                                                width: screenWidth * 0.4,
                                                child: CustomButtonWidget(
                                                  screenWidth: screenWidth,
                                                  toppadding: 10,
                                                  textstyle:
                                                      AppTextStyle.latoBold26(
                                                        context,
                                                      ),
                                                  text: 'Filter',
                                                  color: AppColors.green,
                                                  foregroundcolor: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  onpressed: () {
                                                    Navigator.pop(context);
                                                    context
                                                        .read<AssetsCubit>()
                                                        .filterAssets(
                                                          area: selectedArea
                                                              .value,
                                                          branch: selectedBranch
                                                              .value,
                                                        );
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                width: screenWidth * 0.4,
                                                child: CustomOutlineButtonWidget(
                                                  screenWidth: screenWidth,
                                                  borderColor: AppColors.green,
                                                  topPadding: 10,
                                                  foregroundColor:
                                                      AppColors.green,
                                                  text: 'Clear',
                                                  textStyle:
                                                      AppTextStyle.latoBold26(
                                                        context,
                                                      ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    selectedArea.value = null;
                                                    selectedBranch.value = null;
                                                    areaController.clear();
                                                    branchController.clear();
                                                    context
                                                        .read<AssetsCubit>()
                                                        .getAssets();
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            icon: Icon(
                              Icons.filter_list_rounded,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: RefreshIndicator(child: ListView.builder(
                    itemCount: state.assets.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          context
                              .read<AssetsTicketsCubit>()
                              .getTicketsWithAssetsId(
                            assetId: assets[index].id,
                          );
                          context
                              .read<AssetsRepairCubit>()
                              .getAssetsRepairDetailsWithAssetId(
                            assetID: assets[index].id,
                          );
                          Get.to(
                            AssetsDetailsPage(assets: state.assets[index]),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.all(12),
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
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGreen.withOpacity(
                                      0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  child: ClipRRect(
                                    child: SvgPicture.asset(
                                      'assets/images/${assets[index].type}.svg',
                                      color: AppColors.green,
                                      width: screenWidth * 0.1,
                                      height: screenWidth * 0.1,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text("${assets[index].type}".tr),
                                        Text('${assets[index].barcode}'),
                                      ],
                                    ),
                                    Text(
                                      '${assets[index].branchObject?.name}'.tr,
                                      style: AppTextStyle.latoRegular16(
                                        context,
                                      ).copyWith(color: AppColors.green),
                                    ),
                                    Text(
                                      '${assets[index].branchObject?.areaObject?.name}'
                                          .tr,
                                      style: AppTextStyle.latoRegular16(
                                        context,
                                      ).copyWith(color: AppColors.gray),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Column(
                                    spacing: 10,
                                    children: [
                                      Text("Total Spend".tr),
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
                                              "${assets[index].amount ?? 0}",
                                              style:
                                              AppTextStyle.latoBold16(
                                                context,
                                              ).copyWith(
                                                color: AppColors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              "EGP".tr,
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
                      );
                    },
                  ), onRefresh: (){
                    return context.read<AssetsCubit>().getAssets();
                  }),
                ),
              ],
            );
          } else if (state is GetAssetsFailure) {
            return Center(child: Text(state.errMsg));
          } else {
            return Center(child: Text('No Assets Found'));
          }
        },
      ),
    );
  }
}
