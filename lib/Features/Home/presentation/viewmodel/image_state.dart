part of 'image_cubit.dart';

sealed class ImageState {}

final class ImageInitial extends ImageState {}

final class ImageUpdateLoading extends ImageState {}

final class ImageUpdateSuccess extends ImageState {
  final String? image;

  ImageUpdateSuccess({required this.image});
}

final class ImageUpdateFailed extends ImageState {}
