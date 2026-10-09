import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_list_view.dart';
import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_search_widget.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/utils/widgets/custom_outline_button_widget.dart';
import 'package:efs_misr/generated/app_images.dart';
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
import '../controller/assets_cubit.dart';

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
                      SvgPicture.asset(AppImages.images.excel.path),
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
                      customBottomSheet(context);
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
  }

  void customBottomSheet(BuildContext context) {
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
                    inbutIcon: AppImages.images.address.path,
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
                    inbutIcon: AppImages.images.address.path,
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
                            area: selectedArea?.toInt(),
                            branch: selectedBranch?.toInt(),
                          );

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
