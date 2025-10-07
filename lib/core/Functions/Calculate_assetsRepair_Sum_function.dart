import '../../Features/Home/data/models/assets_repair.dart';

num? calculateTotalAmount(List<AssetsRepair> assetsRepair) {
  num total = 0;
  num count = 0;
  num? singleValue;

  for (final assetsElement in assetsRepair) {
    if (assetsElement.amount != null) {
      total += assetsElement.amount!;
      count++;
      singleValue = assetsElement.amount!;
    }
  }

  // لو في قيمة واحدة بس
  if (count == 1) {
    return singleValue;
  }

  // لو مفيش قيم أصلاً
  if (count == 0) {
    return null;
  }

  // لو أكتر من قيمة، يرجع المجموع
  return total;
}
