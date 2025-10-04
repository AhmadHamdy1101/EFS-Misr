import 'package:efs_misr/Features/Home/data/models/assets_repair.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repo/home_repo.dart';

part 'assets_repair_state.dart';

class AssetsRepairCubit extends Cubit<AssetsRepairState> {
  HomeRepo homeRepo;

  AssetsRepairCubit(this.homeRepo) : super(AssetsRepairInitial());

  Future<void> getAssetsRepairDetails({required BigInt ticketID}) async {
    emit(GetAssetsRepairDataLoading());
    final res = await homeRepo.getAssetsRepairWithTicketID(ticketID: ticketID);
    res.fold(
      (fail) {
        print(fail.message);
        emit(GetAssetsRepairDataFailed(errMsg: fail.message));
      },
      (data) {
        emit(GetAssetsRepairDataSuccess(assetsRepair: data));
      },
    );
  }
}
