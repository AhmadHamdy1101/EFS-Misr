import 'dart:io';

import 'package:efs_misr/Features/Auth/domain/auth_repo.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'image_state.dart';

class ImageCubit extends Cubit<ImageState> {
  ImageCubit(this.authRepo) : super(ImageInitial());

  final AuthRepo authRepo;

  Future<void> uploadProfileImage({
    required UserEntity user,
    required File file,
  }) async {
    if (state is ImageUpdateLoading) return;
    emit(ImageUpdateLoading());
    final result = await authRepo.updateProfileImage(user: user, file: file);
    result.fold(
      (failure) => emit(ImageUpdateFailed(failure.message)),
      (updated) => emit(ImageUpdateSuccess(user: updated)),
    );
  }
}
