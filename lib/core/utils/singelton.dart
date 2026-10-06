
import 'package:efs_misr/Features/Assets_data/data/assets_data_source.dart';
import 'package:efs_misr/Features/Assets_data/data/repo/assets_data_repo_impl.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Home/data/data_source/remote_data_source.dart';
import 'package:efs_misr/Features/Home/data/repo/home_repo_impl.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/Features/Tickets/data/repo/ticket_repo_impl.dart';
import 'package:efs_misr/Features/Tickets/data/ticket_data_soucre.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:get_it/get_it.dart';
import '../../Features/Auth/data/repos/auth_repo_impl.dart';
import '../../Features/Auth/data/source/remote_data_source.dart';
import '../../Features/Auth/domain/auth_repo.dart';


final getIt = GetIt.instance;

void setup() {
  getIt.registerSingleton<AuthRepo>(
    AuthRepoImpl(AuthRemoteDataImpl()),
  );
  getIt.registerSingleton<HomeRepo>(
    HomeRepoImpl(HomeRemoteDataSourceImpl()),
  );

  getIt.registerSingleton<TicketsRepo>(
    TicketRepoImpl(TicketDataSourceImpl()),
  );
  getIt.registerSingleton<AssetsDataRepo>(
    AssetsDataRepoImpl(AssetsDataSourceImpl()),
  );
}