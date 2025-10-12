import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/presentation/pages/ticket_details_page.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_repair_cubit.dart';
import 'package:efs_misr/core/Functions/Capitalize_Function.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/Functions/GetDate_Function.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../viewmodel/assets_tickets_cubit.dart';

class AssetsDetailsPageBody extends StatefulWidget {
  const AssetsDetailsPageBody({super.key, required this.assets});

  final Assets assets;

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
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
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: ClipRRect(
                          child: SvgPicture.asset(
                            'assets/images/${widget.assets.type}.svg',
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(capitalizeEachWord("${widget.assets.type}").tr),
                              Text('${widget.assets.barcode}'),
                            ],
                          ),
                          Text(
                            capitalizeEachWord('${widget.assets.branchObject?.name}').tr,
                            style: AppTextStyle.latoRegular16(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                          Text(
                            capitalizeEachWord('${widget.assets.branchObject!.areaObject!.name}').tr,
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
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.assets.amount ?? 0}',
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
                    width: screenWidth,
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
                                Text('${widget.assets.place}'.tr),
                              ],
                            ),
                            Row(
                              children: [
                                Text('Type:'.tr),
                                Text('${widget.assets.type}'.tr),
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
        SliverFillRemaining(
          child: BlocBuilder<AssetsRepairCubit, AssetsRepairState>(
            buildWhen: (previous, current) =>
                current is GetAssetsRepairDataInAssetsPageLoading ||
                current is GetAssetsRepairDataInAssetsPageFailed ||
                current is GetAssetsRepairDataInAssetsPageSuccess,
            builder: (context, state) {
              if (state is GetAssetsRepairDataInAssetsPageSuccess) {
                return ListView.builder(
                  itemCount: state.assetsRepair.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          isScrollControlled: false,
                          builder: (BuildContext context) {
                            context
                                .read<AssetsTicketsCubit>()
                                .getAssetsWithTicketId(
                                  ticketId:
                                      state.assetsRepair[index].tickets!.id,
                                );
                            context
                                .read<AssetsRepairCubit>()
                                .getAssetsRepairDetails(
                                  ticketID:
                                      state.assetsRepair[index].tickets!.id,
                                );
                            return TicketDetailsPage(
                              tickets: state.assetsRepair[index].tickets!,
                            );
                          },
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
                            horizontal: 10,
                          ),
                          child: Column(
                            spacing: 10,
                            children: [
                              Row(
                                spacing: 15,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.03,
                                      vertical: screenHeight * 0.01,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(60),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.black.withAlpha(30),
                                          spreadRadius: 0,
                                          blurRadius: 11.2,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      child: SvgPicture.asset(
                                        'assets/images/deductions.svg',
                                        color: AppColors.green,
                                        width: screenWidth * 0.09,
                                        height: screenWidth * 0.09,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 5,
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.green,
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                          child: Text(
                                            state
                                                    .assetsRepair[index]
                                                    .variation ??
                                                'No Type'.tr,
                                            style: AppTextStyle.latoRegular15(
                                              context,
                                            ).copyWith(color: AppColors.white),
                                          ),
                                        ),
                                        Text(
                                          getDateFromTimestamp(
                                            state.assetsRepair[index].createdAt,
                                          ),
                                          style: AppTextStyle.latoBold16(
                                            context,
                                          ),
                                        ),
                                        Text(
                                          '${state.assetsRepair[index].comment}',
                                          style: AppTextStyle.latoRegular16(
                                            context,
                                          ).copyWith(color: AppColors.gray),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${state.assetsRepair[index].amount ?? 0}",
                                    style: AppTextStyle.latoBold26(
                                      context,
                                    ).copyWith(color: AppColors.green),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    "EGP".tr,
                                    style: AppTextStyle.latoBold26(
                                      context,
                                    ).copyWith(color: AppColors.green),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              if (state is GetAssetsRepairDataInAssetsPageFailed) {
                return Text(state.errMsg);
              }
              if (state is GetAssetsRepairDataInAssetsPageLoading) {
                return Center(child: CircularProgressIndicator());
              }
              return Text('no assets repair');
            },
          ),
        ),
      ],
    );
  }
}
