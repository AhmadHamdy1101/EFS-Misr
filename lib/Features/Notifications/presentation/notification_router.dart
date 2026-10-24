import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:efs_misr/Features/Tickets/presentation/screens/ticket_details_page.dart';
import 'package:efs_misr/Features/Tracking/presentation/screens/my_location_page.dart';
import 'package:efs_misr/Features/Tracking/presentation/screens/worker_tracking_page.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/utils/singelton.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../domain/entities/app_notification.dart';

/// Opens what a notification points at. Ids in the notification are hints
/// only: the target is re-read with the user's own permissions (RLS), and a
/// deleted or inaccessible target shows a message instead of a broken page.
class NotificationRouter {
  const NotificationRouter._();

  static Future<void> open(
    BuildContext context,
    NotificationTarget target,
    UserEntity user,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    void unavailable() =>
        showAppSnackBar(messenger, 'This item is no longer available.'.tr);

    switch (target) {
      case TicketTarget(:final ticketId):
        final result = await getIt.get<TicketsRepo>().getTicketById(
          BigInt.from(ticketId),
        );
        if (!context.mounted) return;
        final ticket = result.fold((_) => null, (ticket) => ticket);
        if (ticket == null) return unavailable();
        context.read<AssetsTicketsCubit>().getAssetsWithTicketId(
          ticketId: BigInt.from(ticket.id),
        );
        Get.to(() => TicketDetailsPage(tickets: ticket));
      case MyLocationTarget():
        if (user.isAdmin) return unavailable();
        Get.to(() => MyLocationPage(user: user, showBackButton: true));
      case WorkerTrackingTarget(:final technicianId):
        // Live positions are visible to admins only (also enforced by RLS).
        if (!user.isAdmin) return unavailable();
        Get.to(() => WorkerTrackingPage(technicianId: technicianId));
      case NoTarget():
        break;
    }
  }
}
