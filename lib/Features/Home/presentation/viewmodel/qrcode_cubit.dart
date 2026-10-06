import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/assets.dart';

part 'qrcode_state.dart';

class QrcodeCubit extends Cubit<QrcodeState> {
  AssetsDataRepo assetsRepo;

  QrcodeCubit(this.assetsRepo) : super(QrcodeInitial());

  Future<void> getAssetsByQrCode(String barcode) async {
    emit(QrcodeLoading());
    final result = await assetsRepo.getAssetsByQrCode(barcode);
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
