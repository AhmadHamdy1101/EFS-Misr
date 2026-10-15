import 'package:efs_misr/Features/Assets_data/presentation/screens/add_assets_page.dart';
import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_filter_sheet.dart';
import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_list_view.dart';
import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_search_widget.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:efs_misr/generated/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../controller/assets_cubit.dart';

class AssetsPageBody extends StatefulWidget {
  const AssetsPageBody({super.key});

  @override
  State<AssetsPageBody> createState() => _AssetsPageBodyState();
}

class _AssetsPageBodyState extends State<AssetsPageBody> {
  final TextEditingController search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<AssetsCubit>().convertAssetsToExcel();
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

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).buttonTheme.colorScheme?.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
    );
    return RefreshIndicator(
      onRefresh: () => context.read<AssetsCubit>().getAssets(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: AssetsSearchWidget(search: search)),
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
                    style: buttonStyle,
                    onPressed: () => Get.to(() => const AddAssetsPage()),
                    child: Row(
                      spacing: 10,
                      children: [
                        const Icon(Icons.add, color: AppColors.green),
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
                      onPressed: () => AssetsFilterSheet.show(context),
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<AssetsCubit, AssetsState>(
            builder: (context, state) {
              return switch (state) {
                GetAssetsLoading() ||
                AssetsInitial() => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  ),
                ),
                GetAssetsFailure(:final errMsg) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(errMsg)),
                ),
                GetAssetsSuccess(:final assets) when assets.isEmpty =>
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No Assets Found'.tr)),
                  ),
                GetAssetsSuccess(:final assets) => AssetsListView(
                  assets: assets,
                ),
              };
            },
          ),
        ],
      ),
    );
  }
}
