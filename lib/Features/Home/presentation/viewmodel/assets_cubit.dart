import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/assets.dart';
part 'assets_state.dart';

class AssetsCubit extends Cubit<AssetsState> {
  HomeRepo homeRepo;
  AssetsCubit(this.homeRepo) : super(AssetsInitial());

  Future<void> getAssets()async{
    emit(GetAssetsLoading());
    final result = await homeRepo.getAssets();
    result.fold((failure) {
      emit(GetAssetsFailure(errMsg: failure.message));
    }, (assets) {
      emit(GetAssetsSuccess(assets: assets));
    },);
  }
}

