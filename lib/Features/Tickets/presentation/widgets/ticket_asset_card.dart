import 'package:efs_misr/Features/Assets_data/domain/entities/ticket_asset_repairs_entity.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class TicketAssetCard extends StatelessWidget {
  const TicketAssetCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  final TicketAssetRepairsEntity data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final asset = data.asset;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/${asset.type}.svg',
                      colorFilter: const ColorFilter.mode(
                        AppColors.green,
                        BlendMode.srcIn,
                      ),
                      width: 44,
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asset.type.tr),
                        Text(asset.barCode),
                        Text(
                          asset.branchObject.name.tr,
                          style: AppTextStyle.latoRegular16(
                            context,
                          ).copyWith(color: AppColors.green),
                        ),
                        Text(
                          asset.area.tr,
                          style: AppTextStyle.latoRegular16(
                            context,
                          ).copyWith(color: AppColors.gray),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text('Total'.tr, style: AppTextStyle.latoBold20(context)),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          '${data.totalAmount} EGP',
                          style: AppTextStyle.latoBold16(
                            context,
                          ).copyWith(color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (data.repairs.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                for (final repair in data.repairs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(repair.comment ?? '-')),
                        const SizedBox(width: 12),
                        Text(
                          '${repair.amount ?? 0} EGP',
                          style: AppTextStyle.latoBold20(
                            context,
                          ).copyWith(color: AppColors.green),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
