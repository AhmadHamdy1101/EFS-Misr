import 'dart:io';

import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/constants.dart';

part 'image_state.dart';

class ImageCubit extends Cubit<ImageState> {
  HomeRepo homeRepo;
  ImageCubit(this.homeRepo) : super(ImageInitial());
  final picker = ImagePicker();
  final file = Rxn<File>();
  Future<void> updateImage({
    required BigInt userId,
    required String? userName,
  }) async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      emit(ImageUpdateLoading());
      file.value = File(image.path);
      if (file.value != null) {
        final ext = file.value!.path.split('.').last;
        final imageName = '$userName.$ext';

        await supabaseClient.storage
            .from('images')
            .upload(
              imageName,
              file.value!,
              fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
            );
        final imageUrl = supabaseClient.storage
            .from('images')
            .getPublicUrl(imageName);

        final result = await homeRepo.updateUserImage(
          userID: userId,
          image: imageUrl,
        );
        result.fold(
          (l) {
            Get.snackbar(
              "Failed",
              l.message,
              backgroundColor: Colors.red,
              colorText: AppColors.white,
            );
          },
          (r) {
            emit(ImageUpdateSuccess(image: r.image));
          },
        );
      }
    }
  }
}
