// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:crop_your_image/crop_your_image.dart';
// import 'package:efs_misr/core/utils/app_colors.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// final supabaseClient = Supabase.instance.client;
//
// /// دالة رفع صورة المستخدم
// Future<String?> uploadUserImage(BuildContext context, BigInt userId) async {
//   try {
//     // 1. طلب صلاحيات
//     final storageStatus = await Permission.storage.request();
//     final photosStatus = await Permission.photos.request();
//     if (!storageStatus.isGranted && !photosStatus.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("يجب منح صلاحية الوصول إلى الصور")),
//       );
//       return null;
//     }
//
//     // 2. اختيار الصورة من المعرض
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
//     if (result == null || result.files.single.path == null) return null;
//
//     final pickedFile = File(result.files.single.path!);
//     final imageBytes = await pickedFile.readAsBytes();
//
//     // 3. قص الصورة باستخدام crop_your_image
//     Uint8List? croppedData;
//     await showDialog(
//       context: context,
//       builder: (ctx) {
//         final controller = CropController();
//         return AlertDialog(
//           contentPadding: EdgeInsets.zero,
//           content: SizedBox(
//             width: 300,
//             height: 400,
//             child: Crop(
//               image: imageBytes,
//               controller: controller,
//               withCircleUi: false,
//               aspectRatio: 1,
//               onCropped: (data) {
//                 croppedData = data as Uint8List?;
//                 Navigator.pop(ctx);
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => controller.crop(),
//               child: const Text("قص الصورة"),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (croppedData == null) return null;
//
//     // 4. حفظ الصورة المؤقتة بعد القص
//     final tempFile = File(
//       '${pickedFile.parent.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
//     );
//     await tempFile.writeAsBytes(croppedData!);
//
//     // 5. ضغط الصورة
//     final resizedFile = await FlutterImageCompress.compressAndGetFile(
//       tempFile.path,
//       "${tempFile.path}_final.jpg",
//       quality: 85,
//       minWidth: 512,
//       minHeight: 512,
//     );
//     if (resizedFile == null) return null;
//
//     // 6. تجهيز اسم الملف
//     final fileExt = resizedFile.path.split('.').last;
//     final fileName =
//         '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
//     final filePath = 'Photos/$fileName';
//
//     // 7. إظهار Loading
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(child: CircularProgressIndicator()),
//     );
//
//     // 8. رفع الصورة على Supabase Storage
//     await supabaseClient.storage
//         .from('images')
//         .upload(filePath, File(resizedFile.path));
//
//     // 9. جلب الرابط (Public URL)
//     final imageUrl = supabaseClient.storage
//         .from('images')
//         .getPublicUrl(filePath);
//
//     // 10. تحديث المستخدم في Supabase
//     final updatedUser = await supabaseClient
//         .from('users')
//         .update({'image': imageUrl})
//         .eq('id', userId)
//         .select()
//         .single();
//
//     // 11. غلق الـ Loading
//     if (Navigator.canPop(context)) Navigator.pop(context);
//
//     // 12. إشعار بالنجاح
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("تم رفع الصورة بنجاح ✅")));
//
//     // 13. إرجاع الرابط النهائي
//     return updatedUser?['image'] ?? imageUrl;
//   } catch (e) {
//     if (Navigator.canPop(context)) Navigator.pop(context);
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text("خطأ أثناء رفع الصورة: $e")));
//     return null;
//   }
// }
