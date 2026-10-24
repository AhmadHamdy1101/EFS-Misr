import 'package:efs_misr/Features/Accounts/data/accounts_remote_data_source.dart';
import 'package:efs_misr/Features/Accounts/data/accounts_repo_impl.dart';
import 'package:efs_misr/Features/Accounts/domain/accounts_repo.dart';
import 'package:efs_misr/Features/Assets_data/data/assets_data_source.dart';
import 'package:efs_misr/Features/Assets_data/data/repo/assets_data_repo_impl.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_repair_repository.dart';
import 'package:efs_misr/Features/Assets_data/domain/usecases/add_asset_repair_use_case.dart';
import 'package:efs_misr/Features/Notifications/data/notifications_repo_impl.dart';
import 'package:efs_misr/Features/Notifications/data/push_service.dart';
import 'package:efs_misr/Features/Notifications/domain/repo/notifications_repo.dart';
import 'package:efs_misr/Features/Tickets/data/repo/ticket_repo_impl.dart';
import 'package:efs_misr/Features/Tickets/data/ticket_data_source.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:efs_misr/Features/Tracking/data/location_source.dart';
import 'package:efs_misr/Features/Tracking/data/tracking_repo_impl.dart';
import 'package:efs_misr/Features/Tracking/domain/repo/tracking_repo.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Features/Auth/data/repos/auth_repo_impl.dart';
import '../../Features/Auth/data/source/remote_data_source.dart';
import '../../Features/Auth/domain/auth_repo.dart';
import '../lookups/lookup_repo.dart';
import 'theme_service.dart';

final getIt = GetIt.instance;

void setup({required SharedPreferences prefs}) {
  final client = Supabase.instance.client;

  getIt.registerSingleton<ThemeService>(ThemeService(prefs));
  getIt.registerSingleton<LookupRepo>(LookupRepoImpl(client));
  getIt.registerSingleton<AuthRepo>(AuthRepoImpl(AuthRemoteDataImpl(client)));
  getIt.registerSingleton<AccountsRepo>(
    AccountsRepoImpl(AccountsRemoteDataSourceImpl(client)),
  );
  getIt.registerSingleton<TicketsRepo>(
    TicketRepoImpl(TicketDataSourceImpl(client)),
  );
  final assetsDataRepo = AssetsDataRepoImpl(AssetsDataSourceImpl(client));
  getIt.registerSingleton<AssetsDataRepo>(assetsDataRepo);
  getIt.registerSingleton<AssetsRepairRepository>(assetsDataRepo);
  getIt.registerFactory<AddAssetRepairUseCase>(
    () => AddAssetRepairUseCase(getIt.get<AssetsRepairRepository>()),
  );
  getIt.registerSingleton<TrackingRepo>(TrackingRepoImpl(client));
  getIt.registerSingleton<LocationSource>(GeolocatorLocationSource());
  getIt.registerSingleton<DeviceIdStore>(DeviceIdStore(prefs));
  getIt.registerSingleton<NotificationsRepo>(NotificationsRepoImpl(client));
  // Replace with an FCM implementation once Firebase is configured
  // (docs/notifications.md).
  getIt.registerSingleton<PushService>(const DisabledPushService());
}
