import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_repair_list_view.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../controller/assets_tickets_cubit.dart';

class AssetsDetailsPageBody extends StatefulWidget {
  const AssetsDetailsPageBody({super.key, required this.assets});

  final AssetsEntity assets;

  @override
  State<AssetsDetailsPageBody> createState() => _AssetsDetailsPageBodyState();
}

class _AssetsDetailsPageBodyState extends State<AssetsDetailsPageBody> {
  final tickets = <Tickets>[].obs;

  @override
  void initState() {
    super.initState();
    tickets.value = context.read<AssetsTicketsCubit>().tickets;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.all(12),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                spacing: 10,
                children: [
                  Row(
                    spacing: 15,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: ClipRRect(
                          child: SvgPicture.asset(
                            'assets/images/${widget.assets.type}.svg',
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.assets.type.tr),
                              Text(widget.assets.barCode),
                            ],
                          ),
                          Text(
                            widget.assets.branchObject.name.tr,
                            style: AppTextStyle.latoRegular16(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                          Text(
                            widget.assets.area.tr,
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
                                vertical: 5,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xff8FCFAD),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.assets.totalAmount}',
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
                  Container(
                    width: ScreensSize(context).screenWidth,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              children: [
                                Text('Room:'.tr),
                                Text(widget.assets.place.tr),
                              ],
                            ),
                            Row(
                              children: [
                                Text('Type:'.tr),
                                Text(widget.assets.type.tr),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AssetsRepairListView(assetsEntity: widget.assets),
      ],
    );
  }
}
