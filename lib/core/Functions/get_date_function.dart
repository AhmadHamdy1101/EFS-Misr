import 'package:intl/intl.dart';

String getDateFromTimestamp(DateTime? ts) {
  if (ts == null) return '-';
  return DateFormat('d - MMM - yyyy').format(ts);
}
