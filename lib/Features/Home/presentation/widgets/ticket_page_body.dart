import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/presentation/pages/add_Tickets_page.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/tickets_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_inbut_wedget.dart';
import '../../../../core/utils/widgets/custom_outline_button_widget.dart';
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
  final TextEditingController areaController = TextEditingController();
  final TextEditingController branchController = TextEditingController();
  final selectedArea = Rxn<BigInt>();
  final selectedBranch = Rxn<BigInt>();
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

  final List<Map<String, dynamic>> Data = [
    {'name': 'North Cairo', 'value': 'North Cairo'},
    {'name': 'South Cairo', 'value': 'South Cairo'},
    {'name': 'Middle Cairo', 'value': 'Middle Cairo'},
    {'name': 'New Cairo', 'value': 'New Cairo'},
  ];
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    loadArea();
    loadBranch();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
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
                      inbutIcon: 'assets/images/search.svg',
                      inbutHintText: 'Search'.tr,
                      changeToPass: false,
                      textEditingController: search,
                      textInputType: TextInputType.text,
                      onChanged: (search) {
                        context.read<TicketsCubit>().searchTickets(search);
                        return null;
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
                    backgroundColor: Theme.of(
                      context,
                    ).buttonTheme.colorScheme?.primary,
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
                    backgroundColor: Theme.of(
                      context,
                    ).buttonTheme.colorScheme?.primary,
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
                                    Text(
                                      'Area',
                                      style: AppTextStyle.latoBold20(context),
                                    ),
                                    CustomDropdownWidget(
                                      textEditingController: areaController,
                                      inbutIcon: 'assets/images/address.svg',
                                      inbutHintText: 'Area',
                                      selectedValue: selectedArea.value
                                          ?.toString(),
                                      Data: areaRes.toList(),
                                      onChanged: (value) {
                                        selectedArea.value = BigInt.tryParse(
                                          value!,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Column(
                                  spacing: 10,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Branch',
                                      style: AppTextStyle.latoBold20(context),
                                    ),
                                    CustomDropdownWidget(
                                      textEditingController: branchController,
                                      inbutIcon: 'assets/images/address.svg',
                                      inbutHintText: 'Branch',
                                      selectedValue: selectedBranch.value
                                          ?.toString(),
                                      Data: branchRes.toList(),
                                      onChanged: (value) {
                                        selectedBranch.value = BigInt.tryParse(
                                          value!,
                                        );
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
                                                .read<TicketsCubit>()
                                                .filterTickets(
                                              area: selectedArea.value,
                                              branch: selectedBranch.value,
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
                                                .read<TicketsCubit>()
                                                .getTickets();
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
          child: BlocBuilder<TicketsCubit, TicketsState>(
            buildWhen: (previous, current) =>
                current is GetTicketsSuccess ||
                current is GetTicketsFailure ||
                current is GetTicketsLoading,
            builder: (context, state) {
              if (state is GetTicketsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is GetTicketsFailure) {
                return Center(child: Text(state.errMsg));
              }
              if (state is GetTicketsSuccess) {
                return RefreshIndicator.adaptive(
                  child: ListView.builder(
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
                          Get.to(
                            () => TicketDetailsPage(
                              tickets: state.tickets[index],
                            ),
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        // Handle edit action
                                      } else if (value == 'delete') {
                                        context
                                            .read<TicketsCubit>()
                                            .deleteTicket(
                                              ticketID: state.tickets[index].id,
                                            );
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(
                                            'Edit',
                                            style:
                                                AppTextStyle.latoBold20(
                                                  context,
                                                ).copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'Delete',
                                            style:
                                                AppTextStyle.latoBold20(
                                                  context,
                                                ).copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                          ),
                                        ),
                                      ];
                                    },
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  TicketOverViewWidget(
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                    ticketData: state.tickets[index],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  onRefresh: () {
                    return context.read<TicketsCubit>().getTickets();
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
