/// The canonical asset code is the `assets.barcode` value, printed as-is on
/// the label (QR or barcode). Scanners and label printers may add spaces,
/// line breaks or other control characters around it, which are removed
/// here; anything else must match exactly.
///
/// Returns null when nothing usable is left or the value is too long to be
/// a label (a URL or a page of text scanned by mistake).
String? normalizeAssetCode(String raw) {
  final code = raw.replaceAll(_controlChars, '').trim();
  if (code.isEmpty || code.length > maxAssetCodeLength) return null;
  return code;
}

const maxAssetCodeLength = 128;

final _controlChars = RegExp(r'[\u0000-\u001F\u007F]');
