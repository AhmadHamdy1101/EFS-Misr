import 'package:efs_misr/Features/Home/presentation/pages/add_Tickets_page.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_repair_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/tickets_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_inbut_wedget.dart';
import '../../../../core/utils/widgets/ticket_overview_widget.dart';
import '../pages/ticket_details_page.dart';

class TicketPageBody extends StatefulWidget {
  const TicketPageBody({super.key});

  @override
  State<TicketPageBody> createState() => _TicketPageBodyState();
}

class _TicketPageBodyState extends State<TicketPageBody> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            width: MediaQuery
                .sizeOf(context)
                .width * 0.8,
            child: Form(
              key: formKey,
              child: Column(
                spacing: 40,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomInputWidget(
                      inbutIcon: 'assets/images/search.svg',
                      inbutHintText: 'Search'.tr,
                      changeToPass: false,
                      textEditingController: search,
                      textInputType: TextInputType.text,
                      onChanged: (search) {
                        return context.read<TicketsCubit>().searchTickets(
                          search,
                        );
                      },
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
                    backgroundColor: Theme
                        .of(
                      context,
                    )
                        .buttonTheme
                        .colorScheme
                        ?.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {
                    context.read<TicketsCubit>().convertTicketsToExcel();
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
                    backgroundColor: Theme
                        .of(
                      context,
                    )
                        .buttonTheme
                        .colorScheme
                        ?.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {
                    Get.to(AddTicketsPage());
                  },
                  child: Row(
                    spacing: 10,
                    children: [
                      Icon(Icons.add, color: AppColors.green),
                      Text(
                        'Add Ticket'.tr,
                        style: AppTextStyle.latoBold20(
                          context,
                        ).copyWith(color: AppColors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          child: BlocBuilder<TicketsCubit, TicketsState>(
            builder: (context, state) {
              if (state is GetTicketsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is GetTicketsFailure) {
                return Center(child: Text(state.errMsg));
              }
              if (state is GetTicketsSuccess) {
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: state.tickets.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        context
                            .read<AssetsTicketsCubit>()
                            .getAssetsWithTicketId(
                          ticketId: state.tickets[index].id,
                        );
                        context
                            .read<AssetsRepairCubit>()
                            .getAssetsRepairDetails(
                          ticketID: state.tickets[index].id,
                        );
                        Get.to(
                              () =>
                              TicketDetailsPage(tickets: state.tickets[index]),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  PopupMenuButton(
                                      icon: Icon(
                                        Icons.more_horiz,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          // Handle edit action
                                        } else if (value == 'delete') {
                                          // Handle delete action
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit',style: AppTextStyle.latoBold20(context).copyWith(color: Theme.of(context).colorScheme.primary)),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete',style: AppTextStyle.latoBold20(context).copyWith(color: Theme.of(context).colorScheme.primary),),
                                          ),
                                        ];
                                      },
                                  color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  TicketOverViewWidget(
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                    ticketData: state.tickets[index],
                                  ),
                                ],
                              )
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: Text("No Tickets Found"));
            },
          ),
        ),
      ],
    );
  }
}
