import 'package:efs_misr/Features/Assets_data/domain/entities/asset_repair_entity.dart';
import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_repair_card.dart';
import 'package:efs_misr/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../Tickets/presentation/screens/ticket_details_page.dart';
import '../controller/assets_repair_cubit.dart';
import '../controller/assets_tickets_cubit.dart';

class AssetsRepairListView extends StatelessWidget {
  const AssetsRepairListView({super.key});

  void _openTicket(BuildContext context, AssetRepairEntity repair) {
    final ticket = repair.ticket;
    // Load once on tap. Doing this inside the sheet's builder would refetch
    // on every rebuild of the sheet.
    if (ticket != null) {
      context.read<AssetsTicketsCubit>().getAssetsWithTicketId(
        ticketId: BigInt.from(ticket.id),
      );
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ticket == null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No ticket assigned to this repair.',
                style: AppTextStyle.latoRegular24(sheetContext),
              ),
            )
          : TicketDetailsPage(tickets: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetsRepairCubit, AssetsRepairState>(
      buildWhen: (previous, current) =>
          current is GetAssetsRepairDataInAssetsPageLoading ||
          current is GetAssetsRepairDataInAssetsPageFailed ||
          current is GetAssetsRepairDataInAssetsPageSuccess,
      builder: (context, state) {
        if (state is GetAssetsRepairDataInAssetsPageSuccess) {
          final repairs = state.assetsRepair;
          return SliverList.builder(
            itemCount: repairs.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _openTicket(context, repairs[index]),
              child: AssetsRepairCard(assetsRepair: repairs[index]),
            ),
          );
        }
        final Widget child = switch (state) {
          GetAssetsRepairDataInAssetsPageFailed(:final errMsg) => Text(errMsg),
          GetAssetsRepairDataInAssetsPageLoading() =>
            const CircularProgressIndicator(),
          _ => const Text('no assets repair'),
        };
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: child),
        );
      },
    );
  }
}
