import 'package:efs_misr/Features/Tickets/presentation/screens/add_tickets_page.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/generated/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../controller/tickets_cubit.dart';

class FilterSectionWidget extends StatelessWidget {
  const FilterSectionWidget({
    super.key,
    required this.selectedValue,
    required this.Data,
    required this.screenWidth,
  });

  final String? selectedValue;
  final List<Map<String, dynamic>> Data;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
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
                                Text(
                                  'Area',
                                  style: AppTextStyle.latoBold20(context),
                                ),
                                CustomDropdownWidget(
                                  inbutIcon: 'assets/images/address',
                                  inbutHintText: 'Area',
                                  selectedValue: selectedValue,
                                  Data: Data,
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
                                  inbutIcon: 'assets/images/address',
                                  inbutHintText: 'Branch',
                                  selectedValue: selectedValue,
                                  Data: Data,
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            SizedBox(
                              width: screenWidth,
                              child: CustomButtonWidget(
                                screenWidth: screenWidth,
                                toppadding: 10,
                                textstyle: AppTextStyle.latoBold26(context),
                                text: 'Filter',
                                color: AppColors.green,
                                foregroundcolor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icon(Icons.filter_list_rounded, color: AppColors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
