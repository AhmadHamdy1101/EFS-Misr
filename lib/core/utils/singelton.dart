
import 'package:get_it/get_it.dart';

import '../../Features/Auth/data/DataSources/remote_data_source.dart';
import '../../Features/Auth/data/repos/auth_repo_impl.dart';
import '../../Features/Auth/domain/auth_repo.dart';


final getIt = GetIt.instance;

void setup() {
  getIt.registerSingleton<AuthRepo>(
    AuthRepoImpl(AuthRemoteDataImpl()),
  );
}