import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/presentation/screens/assets_details_page.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/load_more_indicator.dart';
import '../controller/assets_repair_cubit.dart';

class AssetsListView extends StatelessWidget {
  const AssetsListView({
    super.key,
    required this.assets,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  final List<AssetsEntity> assets;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final showLoadMore = hasMore && onLoadMore != null;
    return SliverList.builder(
      itemCount: assets.length + (showLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == assets.length) {
          return LoadMoreIndicator(
            isLoading: isLoadingMore,
            onLoadMore: onLoadMore!,
          );
        }
        return GestureDetector(
          onTap: () {
            // Navigate right away; the details page shows a spinner while the
            // repairs load instead of the tap feeling stuck.
            context.read<AssetsRepairCubit>().getAssetsRepairDetailsWithAssetId(
              assetID: BigInt.from(assets[index].id),
            );
            Get.to(() => AssetsDetailsPage(assets: assets[index]));
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.all(12),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                      color: AppColors.lightGreen.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: ClipRRect(
                      child: SvgPicture.asset(
                        'assets/images/${assets[index].type}.svg',
                        colorFilter: const ColorFilter.mode(
                          AppColors.green,
                          BlendMode.srcIn,
                        ),
                        width: ScreensSize(context).screenWidth * 0.1,
                        height: ScreensSize(context).screenHeight * 0.05,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(assets[index].type.tr),
                          Text(assets[index].barCode),
                        ],
                      ),
                      Text(
                        assets[index].branchObject.name.tr,
                        style: AppTextStyle.latoRegular16(
                          context,
                        ).copyWith(color: AppColors.green),
                      ),
                      Text(
                        assets[index].area.tr,
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
                            vertical: ScreensSize(context).screenHeight * 0.01,
                            horizontal: ScreensSize(context).screenWidth * 0.04,
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
                                "${assets[index].totalAmount}",
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
    );
  }
}
