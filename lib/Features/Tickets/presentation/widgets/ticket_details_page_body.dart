import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/add_assets_to_tickets_dailog.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_details_container.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../Assets_data/presentation/controller/assets_repair_cubit.dart';

class TicketDetailsPageBody extends StatefulWidget {
  final Tickets ticket;

  const TicketDetailsPageBody({super.key, required this.ticket});

  @override
  State<TicketDetailsPageBody> createState() => _TicketDetailsPageBodyState();
}

class _TicketDetailsPageBodyState extends State<TicketDetailsPageBody> {
  final TextEditingController damageComment = TextEditingController();
  final TextEditingController amount = TextEditingController();
  final TextEditingController comment = TextEditingController();

  String? selectedValue;
  final selectedRepairValue = ''.obs;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TicketDetailsContainer(
            ticket: widget.ticket,
            damageComment: damageComment,
          ),
        ),
        SliverFillRemaining(
          child: BlocBuilder<AssetsTicketsCubit, AssetsTicketsState>(
            builder: (context, state) {
              if (state is GetAssetsTicketsFailure) {
                return Center(child: Text(state.message));
              }
              if (state is GetAssetsTicketsLoading) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                );
              }
              if (state is GetAssetsTicketsSuccess) {
                final data = state.assetsAndTickets;
                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AddAssetsToTicketsDialog(
                              comment: comment,
                              selectedValue: selectedValue,
                              selectedRepairValue: selectedRepairValue,
                              amount: amount,
                              ticket: widget.ticket,
                              asset: data[index].assets,
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
                            horizontal: 20,
                          ),
                          child: Column(
                            children: [
                              Row(
                                spacing: 15,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      ScreensSize(context).screenWidth * 0.03,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreen.withOpacity(
                                        0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child: ClipRRect(
                                      child: SvgPicture.asset(
                                        'assets/images/${data[index].assets.type}.svg',
                                        color: AppColors.green,
                                        width:
                                            ScreensSize(context).screenWidth *
                                            0.1,
                                        height:
                                            ScreensSize(context).screenWidth *
                                            0.1,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("${data[index].assets.type}".tr),
                                            Text('${data[index].assets.barcode}'),
                                          ],
                                        ),
                                        Text(
                                          '${data[index].assets.branchObject?.name}'
                                              .tr,
                                          style: AppTextStyle.latoRegular16(
                                            context,
                                          ).copyWith(color: AppColors.green),
                                        ),
                                        Text(
                                          '${data[index].assets.branchObject?.area}'
                                              .tr,
                                          style: AppTextStyle.latoRegular16(
                                            context,
                                          ).copyWith(color: AppColors.gray),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    spacing: 5,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Total',
                                        style: AppTextStyle.latoBold26(context),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: AppColors.green,
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        child:
                                            BlocSelector<
                                              AssetsRepairCubit,
                                              AssetsRepairState,
                                              Tickets
                                            >(
                                              selector: (state) {
                                                if (state
                                                    is UpdateTicketDataSuccess) {
                                                  return state.tickets;
                                                }
                                                return widget.ticket;
                                              },
                                              builder: (context, ticket) {
                                                return Text(
                                                  '${ticket.amount} EGP',
                                                  style:
                                                      AppTextStyle.latoBold16(
                                                        context,
                                                      ).copyWith(
                                                        color: AppColors.white,
                                                      ),
                                                );
                                              },
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),

                              // ***************** data assets repair here **************************//
                              SizedBox(
                                // height: 60,
                                width: Get.width,
                                child: BlocBuilder<AssetsRepairCubit, AssetsRepairState>(
                                  buildWhen: (previous, current) =>
                                      current is GetAssetsRepairDataSuccess ||
                                      current is GetAssetsRepairDataLoading ||
                                      current is GetAssetsRepairDataFailed,
                                  builder: (context, state) {
                                    if (state is GetAssetsRepairDataLoading) {
                                      return CircularProgressIndicator();
                                    }
                                    if (state is GetAssetsRepairDataFailed) {
                                      return Text(state.errMsg);
                                    }
                                    if (state is GetAssetsRepairDataSuccess) {
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: state.assetsRepair.length,
                                        itemBuilder: (context, index) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                state.assetsRepair[index].comment ?? '-',
                                              ),
                                              Row(
                                                spacing: 5,
                                                children: [
                                                  Text(
                                                    state
                                                        .assetsRepair[index]
                                                        .amount
                                                        .toString(),
                                                    style:
                                                        AppTextStyle.latoBold20(
                                                          context,
                                                        ).copyWith(
                                                          color:
                                                              AppColors.green,
                                                        ),
                                                  ),
                                                  Text(
                                                    'EGP',
                                                    style:
                                                        AppTextStyle.latoBold20(
                                                          context,
                                                        ).copyWith(
                                                          color:
                                                              AppColors.green,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                    return Text('No Spare parts');
                                  },
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
              return Center(
                child: Text(
                  'No Assets Added Yet',
                  style: AppTextStyle.latoBold23(
                    context,
                  ).copyWith(color: Colors.green),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
