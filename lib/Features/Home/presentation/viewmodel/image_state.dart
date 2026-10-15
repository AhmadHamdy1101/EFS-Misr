part of 'image_cubit.dart';

sealed class ImageState {}

final class ImageInitial extends ImageState {}

final class ImageUpdateLoading extends ImageState {}

final class ImageUpdateSuccess extends ImageState {
  final UserEntity user;

  ImageUpdateSuccess({required this.user});
}

final class ImageUpdateFailed extends ImageState {
  final String errMsg;

  ImageUpdateFailed(this.errMsg);
}
