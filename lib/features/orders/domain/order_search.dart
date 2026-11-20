import 'order.dart';
import 'order_status.dart';

/// Search and grouping for the history screen. Pure functions, no Flutter.
abstract final class OrderSearch {
  /// Arabic folded for matching: no diacritics or tatweel, and the letters
  /// people type interchangeably made equal (أ إ آ → ا, ة → ه, ى → ي).
  /// So «فاطمة» finds «فاطمه» and «أحمد» finds «احمد».
  static String fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[ً-ٰٟـ]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool matches(Order o, String query) {
    final q = fold(query);
    if (q.isEmpty) return true;
    final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
    final haystack = fold(
      [
        o.code,
        o.customerName,
        o.senderName,
        o.recipientName,
        o.customerInstagram,
        o.kind.label,
        o.packageName,
        o.notes,
      ].whereType<String>().join(' '),
    );
    if (haystack.contains(q)) return true;
    // Phone numbers: match on the digits so «0933 12» finds «96393312…».
    final phone = o.customerWhatsapp;
    if (phone != null && digits.length >= 3) {
      final local = digits.startsWith('0') ? digits.substring(1) : digits;
      return phone.contains(local);
    }
    return false;
  }

  /// [status] null means every stage.
  static List<Order> filter(
    List<Order> orders, {
    OrderStatus? status,
    String query = '',
  }) => orders
      .where((o) => status == null || o.status == status)
      .where((o) => matches(o, query))
      .toList(growable: false);

  /// Newest month first; orders inside a month newest first.
  static List<MonthGroup> byMonth(List<Order> orders) {
    final sorted = [...orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final groups = <MonthGroup>[];
    for (final o in sorted) {
      final m = DateTime(o.createdAt.year, o.createdAt.month);
      if (groups.isEmpty || groups.last.month != m) {
        groups.add(MonthGroup(m, []));
      }
      groups.last.orders.add(o);
    }
    return groups;
  }
}

class MonthGroup {
  MonthGroup(this.month, this.orders);

  final DateTime month;
  final List<Order> orders;

  /// What the month brought in: paid or delivered orders only, so unpaid
  /// previews and cancellations don't inflate it.
  int get earnedSyp => orders
      .where((o) => o.status == OrderStatus.paid || o.status == OrderStatus.delivered)
      .fold(0, (sum, o) => sum + o.priceSyp);
}
