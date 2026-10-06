import 'package:efs_misr/Features/Assets_data/presentation/screens/assets_details_page.dart';
import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_list_view.dart';
import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_search_widget.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/utils/widgets/custom_outline_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../core/models/supadart_header.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_button_widget.dart';
import '../../../../core/utils/widgets/custom_dropdown_widget.dart';
import '../../../../core/utils/widgets/custom_inbut_wedget.dart';
import '../controller/assets_cubit.dart';
import '../controller/assets_repair_cubit.dart';
import '../controller/assets_tickets_cubit.dart';

class AssetsPageBody extends StatefulWidget {
  const AssetsPageBody({super.key});

  @override
  State<AssetsPageBody> createState() => _AssetsPageBodyState();
}

class _AssetsPageBodyState extends State<AssetsPageBody> {
  final branchData = <Map<String, dynamic>>[].obs;

  Future<void> loadBranch() async {
    final branch = await supabaseClient.branch.select();
    branchData.value = branch.map<Map<String, dynamic>>((po) {
      return {"name": po["name"], "value": po["id"].toString()};
    }).toList();
  }

  final areaData = <Map<String, dynamic>>[].obs;

  Future<void> loadArea() async {
    final area = await supabaseClient.area.select();
    areaData.value = area.map<Map<String, dynamic>>((po) {
      return {"name": po["name"], "value": po["id"].toString()};
    }).toList();
  }

  BigInt? selectedArea;
  BigInt? selectedBranch;

  String? selectedValue;

  final TextEditingController search = TextEditingController();

  @override
  void initState() {
    loadBranch();
    loadArea();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: AssetsSearchWidget(search: search)),
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
                    // Get.to(AddTicketsPage());
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
                      CustomBottomSheet(context);
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
          child: BlocBuilder<AssetsCubit, AssetsState>(
            builder: (context, state) {
              if (state is GetAssetsLoading) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                );
              } else if (state is GetAssetsSuccess) {
                final assets = state.assets;
                return AssetsListView(assets: assets);
              } else if (state is GetAssetsFailure) {
                return Center(child: Text(state.errMsg));
              } else {
                return Center(child: Text('No Assets Found'));
              }
            },
          ),
        ),
      ],
    );
    return BlocBuilder<AssetsCubit, AssetsState>(
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
                          // Get.to(AddTicketsPage());
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
                                            inbutIcon: 'assets/images/address',
                                            inbutHintText: 'Area',
                                            selectedValue: selectedValue,
                                            Data: areaData.toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                selectedArea = BigInt.tryParse(
                                                  value!,
                                                );
                                              });
                                            },
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
                                            inbutIcon: 'assets/images/address',
                                            inbutHintText: 'Branch',
                                            selectedValue: selectedValue,
                                            Data: branchData.toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                selectedBranch =
                                                    BigInt.tryParse(value!);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      SizedBox(
                                        width: ScreensSize(context).screenWidth,

                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,

                                          children: [
                                            SizedBox(
                                              width:
                                                  ScreensSize(
                                                    context,
                                                  ).screenWidth *
                                                  0.4,
                                              child: CustomButtonWidget(
                                                screenWidth: ScreensSize(
                                                  context,
                                                ).screenWidth,
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
                                                        area: selectedArea,
                                                        branch: selectedBranch,
                                                      );
                                                  print(selectedArea);
                                                  print(selectedBranch);
                                                },
                                              ),
                                            ),
                                            SizedBox(
                                              width:
                                                  ScreensSize(
                                                    context,
                                                  ).screenWidth *
                                                  0.4,
                                              child: CustomOutlineButtonWidget(
                                                screenWidth: ScreensSize(
                                                  context,
                                                ).screenWidth,
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
                child: ListView.builder(
                  itemCount: state.assets.length,
                  itemBuilder: (context, index) {
                    // BigInt total = BigInt.zero;
                    // for (final ticket in assets[index].tickets!) {
                    //   if (ticket.amount != null) {
                    //     total += ticket.amount!;
                    //   }
                    // }

                    return GestureDetector(
                      onTap: () async {
                        context
                            .read<AssetsTicketsCubit>()
                            .getTicketsWithAssetsId(assetId: assets[index].id);
                        context
                            .read<AssetsRepairCubit>()
                            .getAssetsRepairDetailsWithAssetId(
                              assetID: assets[index].id,
                            );
                        Get.to(AssetsDetailsPage(assets: state.assets[index]));
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
                                padding: EdgeInsets.all(
                                  ScreensSize(context).screenWidth * 0.03,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: ClipRRect(
                                  child: SvgPicture.asset(
                                    'assets/images/${assets[index].type}.svg',
                                    color: AppColors.green,
                                    width:
                                        ScreensSize(context).screenWidth * 0.1,
                                    height:
                                        ScreensSize(context).screenHeight * 0.1,
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
                                    '${assets[index].branchObject?.area}'.tr,
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
                                        vertical:
                                            ScreensSize(context).screenHeight *
                                            0.01,
                                        horizontal:
                                            ScreensSize(context).screenWidth *
                                            0.04,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xff8FCFAD),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Row(
                                        spacing: 4,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "${assets[index].amount ?? 0}",
                                            style: AppTextStyle.latoBold16(
                                              context,
                                            ).copyWith(color: AppColors.white),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            "EGP".tr,
                                            style: AppTextStyle.latoBold16(
                                              context,
                                            ).copyWith(color: AppColors.white),
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
                ),
              ),
            ],
          );
        } else if (state is GetAssetsFailure) {
          return Center(child: Text(state.errMsg));
        } else {
          return Center(child: Text('No Assets Found'));
        }
      },
    );
  }

  void CustomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(top: 30, right: 10, left: 10),
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Filter",
                style: AppTextStyle.latoBold26(
                  context,
                ).copyWith(color: AppColors.green),
              ),
              Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Area', style: AppTextStyle.latoBold20(context)),
                  CustomDropdownWidget(
                    inbutIcon: 'assets/images/address',
                    inbutHintText: 'Area',
                    selectedValue: selectedValue,
                    Data: areaData.toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedArea = BigInt.tryParse(value!);
                      });
                    },
                  ),
                ],
              ),
              Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Branch', style: AppTextStyle.latoBold20(context)),
                  CustomDropdownWidget(
                    inbutIcon: 'assets/images/address',
                    inbutHintText: 'Branch',
                    selectedValue: selectedValue,
                    Data: branchData.toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBranch = BigInt.tryParse(value!);
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 5),
              SizedBox(
                width: ScreensSize(context).screenWidth,

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    SizedBox(
                      width: ScreensSize(context).screenWidth * 0.4,
                      child: CustomButtonWidget(
                        screenWidth: ScreensSize(context).screenWidth,
                        toppadding: 10,
                        textstyle: AppTextStyle.latoBold26(context),
                        text: 'Filter',
                        color: AppColors.green,
                        foregroundcolor: Theme.of(context).primaryColor,
                        onpressed: () {
                          Navigator.pop(context);
                          context.read<AssetsCubit>().filterAssets(
                            area: selectedArea,
                            branch: selectedBranch,
                          );
                          print(selectedArea);
                          print(selectedBranch);
                        },
                      ),
                    ),
                    SizedBox(
                      width: ScreensSize(context).screenWidth * 0.4,
                      child: CustomOutlineButtonWidget(
                        screenWidth: ScreensSize(context).screenWidth,
                        borderColor: AppColors.green,
                        topPadding: 10,
                        foregroundColor: AppColors.green,
                        text: 'Clear',
                        textStyle: AppTextStyle.latoBold26(context),
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<AssetsCubit>().getAssets();
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
  }
}
