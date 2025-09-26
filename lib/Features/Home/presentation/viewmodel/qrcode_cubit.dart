import 'package:efs_misr/Features/Home/data/models/assets.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'qrcode_state.dart';

class QrcodeCubit extends Cubit<QrcodeState> {
  HomeRepo homeRepo;

  QrcodeCubit(this.homeRepo) : super(QrcodeInitial());

  Future<void> getAssetsByQrCode(String barcode) async {
    emit(QrcodeLoading());
    final result = await homeRepo.getAssetsByQrCode(barcode);
    result.fold(
      (failure) {
        emit(QrcodeFailed(errMsg: failure.message));
      },
      (assets) {

        emit(QrcodeSuccess(assets: assets));
      },
    );
  }
}
