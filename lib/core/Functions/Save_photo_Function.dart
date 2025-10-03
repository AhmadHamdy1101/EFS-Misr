import 'dart:io';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClient = Supabase.instance.client;

/// BottomSheet لاختيار مصدر الصورة
Future<ImageSource?> _pickImageSource(BuildContext context) async {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              iconColor: Colors.green,
              textColor: Colors.black,
              title: const Text('Choose From Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take From Camera'),
              iconColor: Colors.green,
              textColor: Colors.black,
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );
}

/// دالة رفع صورة المستخدم
Future<String?> uploadUserImage(BuildContext context, BigInt userId) async {
  try {
    // 1. طلب صلاحيات
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    if (!cameraStatus.isGranted && !storageStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يجب منح صلاحيات الكاميرا أو التخزين")),
      );
      return null;
    }

    // 2. اختيار المصدر (كاميرا / جاليري)
    final source = await _pickImageSource(context);
    if (source == null) return null;

    // 3. اختيار الصورة
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return null;

    // 4. قص الصورة
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cut Image',
          toolbarColor: AppColors.green,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Cut Image'),
      ],
    );
    if (croppedFile == null) return null;

    // 5. Resize + Compress
    final resizedFile = await FlutterImageCompress.compressAndGetFile(
      croppedFile.path,
      "${croppedFile.path}_final.jpg",
      quality: 80,
      minWidth: 512,
      minHeight: 512,
    );
    if (resizedFile == null) return null;

    // 6. تجهيز اسم الملف
    final fileExt = resizedFile.path.split('.').last;
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'Photos/$fileName';

    // 7. إظهار Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 8. رفع الصورة على Supabase Storage
    await supabaseClient.storage.from('images').upload(filePath, File(resizedFile.path));

    // 9. جلب الرابط (Public URL)
    final imageUrl = supabaseClient.storage.from('images').getPublicUrl(filePath);

    // 10. تحديث جدول المستخدم + إرجاع الصف
    final updatedUser = await supabaseClient
        .from('users')
        .update({'image': imageUrl})
        .eq('id', userId)
        .select()
        .single();

    // 11. غلق Loading
    if (Navigator.canPop(context)) Navigator.pop(context);

    // 12. إشعار بالنجاح
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم رفع الصورة بنجاح ✅")),
    );

    // ✅ تحديث الـ model فورًا
    if (updatedUser != null && updatedUser['image'] != null) {
      return updatedUser['image'] as String;
    } else {
      return imageUrl; // fallback
    }
  } catch (e) {
    // غلق Loading لو فيه Error
    if (Navigator.canPop(context)) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error uploading image: $e")),
    );
    return null;
  }
}