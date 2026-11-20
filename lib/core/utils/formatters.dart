import 'package:intl/intl.dart';

/// Presentation formatting. Storage stays raw (integers of SYP, UTC times).
///
/// Figures use Western digits on purpose: codes, prices and phone numbers
/// get copied into WhatsApp as-is (docs/DESIGN.md §4).
abstract final class Fmt {
  static final NumberFormat _int = NumberFormat('#,##0', 'en');

  /// 1500 → «1,500 ل.س»
  static String syp(num value) => '${_int.format(value.round())} ل.س';

  /// 1500 → «1,500»
  static String number(num value) => _int.format(value.round());

  static const _months = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران', //
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
  ];

  /// Levantine month names, which is what customers write and read.
  static String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'ص' : 'م'}';
  }

  /// «قبل ٥ دقائق» style relative time, with Western digits.
  static String ago(DateTime then, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(then);
    if (diff.inMinutes < 1) return 'هلّق';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
    if (diff.inDays == 1) return 'مبارح';
    if (diff.inDays < 7) return 'قبل ${diff.inDays} أيام';
    return dayMonth(then);
  }

  /// Wraps a Latin run (an order code, a phone number) in Unicode isolates
  /// so RTL text never reorders it: «R-K3F9A» never becomes «K3F9A-R».
  static String ltr(String s) => '$_lri$s$_pdi';

  /// LEFT-TO-RIGHT ISOLATE and POP DIRECTIONAL ISOLATE, built from code
  /// points so no invisible control characters sit in the source.
  static final String _lri = String.fromCharCode(0x2066);
  static final String _pdi = String.fromCharCode(0x2069);
}
