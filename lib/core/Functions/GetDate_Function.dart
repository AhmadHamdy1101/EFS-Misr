import 'package:intl/intl.dart';

String getDateFromTimestamp(DateTime ts) {
  DateTime dateTime = ts;
  return DateFormat('d - MMM - yyyy').format(dateTime);
}