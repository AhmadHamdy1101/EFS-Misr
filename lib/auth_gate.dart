import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'Features/Accounts/presentation/controller/accounts_cubit.dart';
import 'Features/Assets_data/presentation/controller/assets_cubit.dart';
import 'Features/Auth/presentation/pages/auth_page.dart';
import 'Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'Features/Notifications/presentation/controller/notifications_cubit.dart';
import 'Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'Features/Tracking/presentation/controller/my_tracking_cubit.dart';
import 'Features/Tracking/presentation/controller/tracking_control_cubit.dart';
import 'core/entities/user_entity.dart';
import 'core/layout/adaptive_layout.dart';
import 'core/layout/desktop_layout.dart';
import 'core/layout/mobile_layout.dart';
import 'core/layout/tablet_layout.dart';
import 'core/lookups/lookup_repo.dart';
import 'core/utils/app_colors.dart';
import 'core/utils/singelton.dart';
import 'core/utils/widgets/app_snack_bar.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _homeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkSession();
  }

  /// Starts per-user data when a session begins.
  void _onSignedIn(UserEntity user) {
    context.read<TicketsCubit>().start();
    context.read<AssetsCubit>().getAssets();
    context.read<NotificationsCubit>().start(user);
    // Admins watch everyone; other staff get requests and can share.
    if (user.isAdmin) {
      context.read<TrackingControlCubit>().start();
    } else {
      context.read<MyTrackingCubit>().start(user);
    }
  }

  /// The data cubits live above the navigator, so they must be cleared
  /// explicitly or the next user would see the previous user's data.
  void _onSignedOut() {
    context.read<TicketsCubit>().reset();
    context.read<AssetsCubit>().reset();
    context.read<AccountsCubit>().reset();
    // Stops location publishing and realtime channels for the old user.
    context.read<TrackingControlCubit>().reset();
    context.read<MyTrackingCubit>().reset();
    context.read<NotificationsCubit>().reset();
    getIt.get<LookupRepo>().clearCache();
    Get.until((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthCubitState>(
      listenWhen: (previous, current) =>
          (previous is SessionExist) != (current is SessionExist) ||
          current is LoginFailure ||
          current is SessionLoadFailed,
      listener: (context, state) {
        switch (state) {
          case SessionExist(:final user):
            _onSignedIn(user);
          case LoginFailure(:final errorMsg):
            _onSignedOut();
            showAppSnackBar(
              ScaffoldMessenger.of(context),
              errorMsg,
              isError: true,
            );
          case SessionLoadFailed(:final errMsg):
            _onSignedOut();
            showAppSnackBar(
              ScaffoldMessenger.of(context),
              errMsg,
              isError: true,
            );
          default:
            _onSignedOut();
        }
      },
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return Container(
            color: Theme.of(context).primaryColor,
            child: const Center(
              child: CircularProgressIndicator(
                backgroundColor: AppColors.green,
              ),
            ),
          );
        }
        if (state is SessionExist) {
          final user = state.user;
          return AdaptiveLayout(
            mobileLayout: (_) => MobileLayout(user: user, homeKey: _homeKey),
            tabletLayout: (_) => TabletLayout(user: user, homeKey: _homeKey),
            desktopLayout: (_) => DesktopLayout(user: user, homeKey: _homeKey),
          );
        }
        return const AuthPage();
      },
    );
  }
}
