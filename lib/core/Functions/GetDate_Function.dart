import 'package:intl/intl.dart';

String getDateFromTimestamp(DateTime? ts) {
  return DateFormat('d - MMM - yyyy').format(ts!);
}