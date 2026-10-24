import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../domain/entities/tracking_session.dart';
import '../../domain/entities/tracking_worker.dart';
import '../controller/tracking_control_cubit.dart';
import 'tracking_widgets.dart';

/// "Request live location" confirmation. Sends the request through
/// [TrackingControlCubit] and returns the new session, or null if cancelled
/// or rejected by the server (the reason is shown in a snackbar).
class RequestLocationDialog extends StatefulWidget {
  const RequestLocationDialog({
    super.key,
    required this.worker,
    this.ticketId,
    this.ticketLabel,
  });

  final TrackingWorker worker;
  final int? ticketId;
  final String? ticketLabel;

  static Future<TrackingSession?> show(
    BuildContext context, {
    required TrackingWorker worker,
    int? ticketId,
    String? ticketLabel,
  }) {
    return showDialog<TrackingSession>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TrackingControlCubit>(),
        child: RequestLocationDialog(
          worker: worker,
          ticketId: ticketId,
          ticketLabel: ticketLabel,
        ),
      ),
    );
  }

  @override
  State<RequestLocationDialog> createState() => _RequestLocationDialogState();
}

class _RequestLocationDialogState extends State<RequestLocationDialog> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<TrackingControlCubit>().requestLocation(
      widget.worker.user,
      ticketId: widget.ticketId,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _sending = false);
        showAppSnackBar(messenger, failure.message, isError: true);
      },
      (session) {
        Navigator.of(context).pop(session);
        showAppSnackBar(
          messenger,
          session.status == TrackingStatus.active
              ? '${widget.worker.user.name} ${'is already sharing.'.tr}'
              : 'Request sent.'.tr,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.worker.user;
    final now = context.read<TrackingControlCubit>().state.now;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: trackingTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Request live location'.tr,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${'Send a location sharing request to'.tr} ${user.name}?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray, fontSize: 16),
            ),
            if (widget.ticketLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.ticketLabel!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: trackingCardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  WorkerAvatar(user: user, radius: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (user.position?.name ?? user.role).tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  TrackingStatusChip(state: widget.worker.stateAt(now)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.green,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${'Sharing starts only after'.tr} ${user.name} '
                    '${'approves your request.'.tr}',
                    style: const TextStyle(color: AppColors.gray, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TrackingPrimaryButton(
              label: 'Send request',
              icon: Icons.location_on,
              loading: _sending,
              onPressed: _send,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _sending ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel'.tr,
                style: const TextStyle(color: AppColors.gray, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
