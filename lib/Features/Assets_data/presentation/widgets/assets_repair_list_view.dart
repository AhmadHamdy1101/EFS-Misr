import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_repair_card.dart';
import 'package:efs_misr/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../Tickets/presentation/screens/ticket_details_page.dart';
import '../controller/assets_repair_cubit.dart';
import '../controller/assets_tickets_cubit.dart';

class AssetsRepairListView extends StatelessWidget {
  const AssetsRepairListView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
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

                      builder: (BuildContext context) {
                        final ticket = state.assetsRepair[index].ticket;
                        if (ticket == null) {
                          return  Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No ticket assigned to this repair.',style: AppTextStyle.latoRegular24(context),),
                          );
                        }

                        context
                            .read<AssetsTicketsCubit>()
                            .getAssetsWithTicketId(
                              ticketId: BigInt.from(ticket.id),
                            );
                        return TicketDetailsPage(tickets: ticket);
                      },
                    );
                  },
                  child: AssetsRepairCard(
                    assetsRepair: state.assetsRepair[index],
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
    );
  }
}
