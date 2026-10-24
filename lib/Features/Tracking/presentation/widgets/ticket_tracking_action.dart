import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../domain/entities/tracking_worker.dart';
import '../controller/tracking_control_cubit.dart';
import '../screens/worker_tracking_page.dart';
import 'request_location_dialog.dart';
import 'tracking_widgets.dart';

/// Ticket details card for admins: live-location state of the assigned
/// engineer, with Request / View actions tied to this ticket.
class TicketTrackingAction extends StatelessWidget {
  const TicketTrackingAction({super.key, required this.ticket});

  final TicketEntity ticket;

  static const _closed = {
    TicketStatus.completed,
    TicketStatus.canceled,
    TicketStatus.rejected,
  };

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAdmin = authState is SessionExist && authState.user.isAdmin;
    if (!isAdmin || _closed.contains(ticket.status)) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<TrackingControlCubit, TrackingControlState>(
      builder: (context, state) {
        final engineerId = ticket.engineer;
        final worker = engineerId == null
            ? null
            : state.workerById(BigInt.from(engineerId));
        final trackingState = worker?.stateAt(state.now);
        final label = '${'Ticket'.tr} #${ticket.oricalID ?? ticket.id}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: trackingCardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.green, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live location'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker == null
                          ? (engineerId == null
                                ? 'Assign a technician to request live location.'
                                      .tr
                                : state.loading
                                ? 'Loading technician…'.tr
                                : 'This technician is not enabled for live tracking.'
                                      .tr)
                          : worker.user.name,
                      style: const TextStyle(color: AppColors.gray),
                    ),
                    if (trackingState != null) ...[
                      const SizedBox(height: 6),
                      TrackingStatusChip(state: trackingState),
                    ],
                  ],
                ),
              ),
              if (worker != null)
                _button(context, worker, trackingState!, label),
            ],
          ),
        );
      },
    );
  }

  Widget _button(
    BuildContext context,
    TrackingWorker worker,
    WorkerTrackingState trackingState,
    String label,
  ) {
    void openPage() => Get.to(
      () => WorkerTrackingPage(
        technicianId: worker.user.id,
        ticketId: ticket.id,
        ticketLabel: label,
      ),
    );
    if (trackingState == WorkerTrackingState.notSharing) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          shape: const StadiumBorder(),
        ),
        onPressed: () async {
          final session = await RequestLocationDialog.show(
            context,
            worker: worker,
            ticketId: ticket.id,
            ticketLabel: label,
          );
          if (session != null) openPage();
        },
        child: Text('Request'.tr),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        side: const BorderSide(color: AppColors.green, width: 2),
        shape: const StadiumBorder(),
      ),
      onPressed: openPage,
      child: Text('View'.tr),
    );
  }
}
