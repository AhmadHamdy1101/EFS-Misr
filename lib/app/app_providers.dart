import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Features/Accounts/domain/accounts_repo.dart';
import '../Features/Accounts/presentation/controller/accounts_cubit.dart';
import '../Features/Assets_data/domain/repo/assets_data_repo.dart';
import '../Features/Assets_data/domain/repo/assets_repair_repository.dart';
import '../Features/Assets_data/domain/usecases/add_asset_repair_use_case.dart';
import '../Features/Assets_data/presentation/controller/assets_cubit.dart';
import '../Features/Assets_data/presentation/controller/assets_repair_cubit.dart';
import '../Features/Assets_data/presentation/controller/assets_tickets_cubit.dart';
import '../Features/Assets_data/presentation/controller/qrcode_cubit.dart';
import '../Features/Auth/domain/auth_repo.dart';
import '../Features/Auth/presentation/viewmodel/auth_cubit.dart';
import '../Features/Home/presentation/viewmodel/check_internet_cubit.dart';
import '../Features/Home/presentation/viewmodel/image_cubit.dart';
import '../Features/Tickets/domain/repo/tickets_repo.dart';
import '../Features/Tickets/presentation/controller/tickets_cubit.dart';
import '../core/utils/singelton.dart';

/// App-wide cubits. They sit above the navigator so every pushed page can
/// read them; per-user data is cleared on sign-out by `AuthGate`.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CheckInternetCubit(Connectivity())),
        BlocProvider(create: (_) => AuthCubit(getIt.get<AuthRepo>())),
        BlocProvider(
          create: (_) => TicketsCubit(ticketsRepo: getIt.get<TicketsRepo>()),
        ),
        BlocProvider(create: (_) => AssetsCubit(getIt.get<AssetsDataRepo>())),
        BlocProvider(create: (_) => QrcodeCubit(getIt.get<AssetsDataRepo>())),
        BlocProvider(create: (_) => AccountsCubit(getIt.get<AccountsRepo>())),
        BlocProvider(
          create: (_) => AssetsTicketsCubit(
            getIt.get<AssetsDataRepo>(),
            getIt.get<AssetsRepairRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => AssetsRepairCubit(
            assetsRepairRepository: getIt.get<AssetsRepairRepository>(),
            addAssetRepair: getIt.get<AddAssetRepairUseCase>(),
          ),
        ),
        BlocProvider(create: (_) => ImageCubit(getIt.get<AuthRepo>())),
      ],
      child: child,
    );
  }
}
