import 'package:efs_misr/Features/Notifications/presentation/controller/notifications_cubit.dart';
import 'package:efs_misr/Features/Notifications/presentation/notification_router.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/qr_view.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/Features/Tracking/presentation/controller/my_tracking_cubit.dart';
import 'package:efs_misr/Features/Tracking/presentation/screens/my_location_page.dart';
import 'package:efs_misr/Features/Tracking/presentation/screens/tracking_control_page.dart';
import 'package:efs_misr/Features/Tracking/presentation/widgets/incoming_request_card.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/widgets/custom_navigation_bar.dart';
import '../../../Tickets/presentation/screens/ticket_page.dart';
import '../widgets/home_page_body.dart';
import '../../../Accounts/presentation/screens/acounts_page.dart';
import '../../../Assets_data/presentation/screens/assets_page.dart';
import 'menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final UserEntity user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  int _shownMessageId = 0;
  String? _promptedRequestId;
  int _openedRequestId = 0;
  int _bannerShownId = 0;

  static const _locationIcon = 'assets/images/location.svg';

  bool get _isAdmin => widget.user.isAdmin;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tabs = <(String, Widget)>[
      ("assets/images/home.svg", HomePageBody(user: widget.user)),
      ("assets/images/assets.svg", const AssetsPage()),
      ("assets/images/ticket.svg", const TicketPage()),
      (
        _locationIcon,
        _isAdmin
            ? const TrackingControlPage()
            : MyLocationPage(user: widget.user),
      ),
      if (_isAdmin) ("assets/images/profile.svg", const AccountsPage()),
      ("assets/images/menu.svg", MenuPage(user: widget.user)),
    ];
    final index = selectedIndex.clamp(0, tabs.length - 1);
    final locationTab = tabs.indexWhere((tab) => tab.$1 == _locationIcon);

    return MultiBlocListener(
      listeners: [
        BlocListener<NotificationsCubit, NotificationsState>(
          listenWhen: (previous, current) =>
              previous.latestId != current.latestId ||
              previous.openRequestId != current.openRequestId,
          listener: _onNotificationEvent,
        ),
        BlocListener<MyTrackingCubit, MyTrackingState>(
          listenWhen: (previous, current) =>
              previous.messageId != current.messageId ||
              (current.pendingRequest != null &&
                  current.pendingRequest?.id != previous.pendingRequest?.id),
          listener: (context, state) {
            if (state.message != null && state.messageId != _shownMessageId) {
              _shownMessageId = state.messageId;
              showAppSnackBar(ScaffoldMessenger.of(context), state.message!.tr);
            }
            // A new request while on another tab: ask right away. On the
            // location tab the request card is already on screen.
            final request = state.pendingRequest;
            if (request != null &&
                request.id != _promptedRequestId &&
                index != locationTab) {
              _promptedRequestId = request.id;
              showIncomingRequestDialog(context, request);
            }
          },
        ),
      ],
      child: _scaffold(tabs, index, screenWidth),
    );
  }

  /// A tapped push opens its target; a notification arriving while the app
  /// is open shows a banner with a View action.
  void _onNotificationEvent(BuildContext context, NotificationsState state) {
    final target = state.openRequest;
    if (target != null && state.openRequestId != _openedRequestId) {
      _openedRequestId = state.openRequestId;
      NotificationRouter.open(context, target, widget.user);
      return;
    }
    final latest = state.latest;
    if (latest == null || state.latestId == _bannerShownId) return;
    _bannerShownId = state.latestId;
    // Tracking events already have their own prompt (technician dialog) or
    // notice (admin control screen).
    if (latest.type.startsWith('tracking.')) return;
    final language = Get.locale?.languageCode ?? 'en';
    final cubit = context.read<NotificationsCubit>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(latest.titleFor(language)),
        action: SnackBarAction(
          label: 'View'.tr,
          onPressed: () async {
            await cubit.markRead(latest);
            if (context.mounted) {
              await NotificationRouter.open(
                context,
                latest.target,
                widget.user,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _scaffold(List<(String, Widget)> tabs, int index, double screenWidth) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => Get.to(() => const QRScanPage()),
        child: SvgPicture.asset(
          'assets/images/Qr code scanner.svg',
          width: screenWidth * 0.07,
        ),
      ),
      // IndexedStack keeps every tab alive, so switching tabs doesn't refetch
      // data or lose search text and scroll position.
      body: IndexedStack(
        index: index,
        children: [for (final tab in tabs) tab.$2],
      ),
      bottomNavigationBar: CustomBottomNav(
        icons: [for (final tab in tabs) tab.$1],
        selectedIndex: index,
        onPressed: (i) => setState(() => selectedIndex = i),
      ),
    );
  }
}
