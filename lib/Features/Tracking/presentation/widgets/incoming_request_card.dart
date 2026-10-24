import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/tracking_session.dart';
import '../controller/my_tracking_cubit.dart';
import 'tracking_widgets.dart';

/// A pending location request with the consent explanation and the
/// Accept / Decline actions. Accepting asks for location permission first.
class IncomingRequestCard extends StatelessWidget {
  const IncomingRequestCard({super.key, required this.request, this.onDone});

  final TrackingSession request;

  /// Called after a successful accept or decline (e.g. to close a dialog).
  final VoidCallback? onDone;

  Future<void> _respond(BuildContext context, {required bool accept}) async {
    final cubit = context.read<MyTrackingCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = accept ? await cubit.accept() : await cubit.decline();
    result.fold(
      (failure) => showAppSnackBar(messenger, failure.message, isError: true),
      (_) {
        if (accept && cubit.state.isActive) {
          showAppSnackBar(messenger, 'You are now sharing your location.'.tr);
        }
        onDone?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<MyTrackingCubit, bool>((c) => c.state.busy);
    final branch = context.select<MyTrackingCubit, String?>(
      (c) => c.state.branch?.name,
    );
    final expires = request.expiresAt;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.green, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: trackingTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: AppColors.green),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live location request'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'An administrator asked to see your location.'.tr,
                      style: const TextStyle(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (request.ticketId != null)
            _line(
              Icons.confirmation_number_outlined,
              '${'Ticket'.tr} #${request.ticketId}',
            ),
          if (branch != null) _line(Icons.account_balance_outlined, branch),
          if (expires != null)
            _line(
              Icons.timer_outlined,
              '${'Expires at'.tr} ${DateFormat('hh:mm a').format(expires)}',
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Only administrators can see your location, and only until '
                          'you stop sharing or the ticket is closed. Nothing is '
                          'shared unless you accept.'
                      .tr,
                  style: const TextStyle(color: AppColors.gray, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray,
                    side: const BorderSide(color: AppColors.gray),
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: busy
                      ? null
                      : () => _respond(context, accept: false),
                  child: Text('Decline'.tr),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: busy
                      ? null
                      : () => _respond(context, accept: true),
                  child: Text('Accept & share'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Shows [IncomingRequestCard] in a dialog; used when a request arrives while
/// the technician is on another tab.
Future<void> showIncomingRequestDialog(
  BuildContext context,
  TrackingSession request,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: context.read<MyTrackingCubit>(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: BlocListener<MyTrackingCubit, MyTrackingState>(
          // Close if the request is answered elsewhere, expires or is cancelled.
          listenWhen: (previous, current) =>
              current.pendingRequest?.id != request.id,
          listener: (_, _) => Navigator.of(dialogContext).maybePop(),
          child: IncomingRequestCard(
            request: request,
            onDone: () => Navigator.of(dialogContext).maybePop(),
          ),
        ),
      ),
    ),
  );
}
