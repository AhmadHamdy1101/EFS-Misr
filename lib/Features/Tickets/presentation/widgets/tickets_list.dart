import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/tickets_edit_pop_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/widgets/load_more_indicator.dart';
import '../controller/tickets_cubit.dart';
import '../screens/ticket_details_page.dart';

/// The paged ticket list as a lazy sliver; its last row loads the next page.
class TicketsList extends StatelessWidget {
  const TicketsList({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        return switch (state) {
          HomeInitial() || GetTicketsLoading() => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          GetTicketsFailure(:final errMsg) => _message(errMsg),
          GetTicketsSuccess(:final listError?) => _message(listError),
          GetTicketsSuccess(:final tickets) when tickets.isEmpty => _message(
            'No Tickets Found'.tr,
          ),
          GetTicketsSuccess(
            :final tickets,
            :final hasMore,
            :final isLoadingMore,
          ) =>
            SliverList.builder(
              itemCount: tickets.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == tickets.length) {
                  return LoadMoreIndicator(
                    isLoading: isLoadingMore,
                    onLoadMore: context.read<TicketsCubit>().loadMore,
                  );
                }
                final ticket = tickets[index];
                return GestureDetector(
                  onTap: () {
                    context.read<AssetsTicketsCubit>().getAssetsWithTicketId(
                      ticketId: BigInt.from(ticket.id),
                    );
                    Get.to(() => TicketDetailsPage(tickets: ticket));
                  },
                  child: TicketsEditPopMenu(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    tickets: ticket,
                  ),
                );
              },
            ),
        };
      },
    );
  }

  Widget _message(String text) => SliverFillRemaining(
    hasScrollBody: false,
    child: Center(child: Text(text)),
  );
}
