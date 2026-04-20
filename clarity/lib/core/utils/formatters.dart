import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat('¥#,##0.0', 'zh_CN');
final _dateFormat = DateFormat('MM/dd', 'zh_CN');
final _weekdayFormat = DateFormat('E', 'zh_CN');

String formatCurrency(double amount) => _currencyFormat.format(amount);

String formatDate(DateTime date) => _dateFormat.format(date);

String formatWeekday(DateTime date) => _weekdayFormat.format(date);

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}

String formatHms(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
