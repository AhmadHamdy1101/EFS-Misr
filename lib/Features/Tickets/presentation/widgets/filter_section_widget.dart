import 'package:efs_misr/Features/Tickets/presentation/screens/add_tickets_page.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_filter_sheet.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/generated/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../controller/tickets_cubit.dart';

class FilterSectionWidget extends StatelessWidget {
  const FilterSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _ActionButton(
              label: 'Export',
              icon: SvgPicture.asset(AppImages.images.excel.path),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await context
                    .read<TicketsCubit>()
                    .convertTicketsToExcel();
                if (!context.mounted) return;
                result.fold(
                  (failure) => messenger.showSnackBar(
                    SnackBar(content: Text(failure.message)),
                  ),
                  (status) => messenger.showSnackBar(
                    SnackBar(
                      content: Text(excelExportStatusMessage(status).tr),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Add Ticket',
              icon: const Icon(Icons.add, color: AppColors.green),
              onPressed: () => Get.to(() => const AddTicketsPage()),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Filter'.tr,
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const TicketFilterSheet(),
              ),
              icon: const Icon(
                Icons.filter_list_rounded,
                color: AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(
        label.tr,
        style: AppTextStyle.latoBold20(
          context,
        ).copyWith(color: AppColors.green),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
