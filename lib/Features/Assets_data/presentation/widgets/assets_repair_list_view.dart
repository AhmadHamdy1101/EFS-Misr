import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/presentation/widgets/assets_repair_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../Tickets/presentation/screens/ticket_details_page.dart';
import '../controller/assets_repair_cubit.dart';
import '../controller/assets_tickets_cubit.dart';

class AssetsRepairListView extends StatelessWidget {
  const AssetsRepairListView({super.key, required this.assetsEntity});

  final AssetsEntity assetsEntity;

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
                      isScrollControlled: false,
                      builder: (BuildContext context) {
                        context
                            .read<AssetsTicketsCubit>()
                            .getAssetsWithTicketId(
                              ticketId: state.assetsRepair[index].tickets!.id,
                            );
                        context
                            .read<AssetsRepairCubit>()
                            .getAssetsRepairDetails(
                              ticketID: state.assetsRepair[index].tickets!.id,
                              assetID: BigInt.from(assetsEntity.id),
                            );
                        if (state.assetsRepair[index].tickets == null) {
                          return Text('No tickets assigned to this asset');
                        }
                        else {
                          return TicketDetailsPage(
                          tickets: state.assetsRepair[index].tickets!,
                        );
                        }
                      },
                    );
                  },
                  child: AssetsRepairCard(assetsRepair: state.assetsRepair[index],),
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
