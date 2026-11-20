import 'order.dart';
import 'order_source.dart';
import 'order_status.dart';

/// The one boundary between the app and wherever orders live.
///
/// Two implementations: Supabase (real orders, realtime) and an in-memory
/// demo seeded with fictional orders. Screens never know which one they have.
abstract interface class OrderRepository {
  /// Every order, newest first, re-emitted whenever anything changes —
  /// including changes made from another device.
  Stream<List<Order>> watchOrders();

  /// [paidWith] is recorded when moving to [OrderStatus.paid].
  Future<void> moveTo(
    String orderId,
    OrderStatus status, {
    PaymentMethod? paidWith,
  });

  /// The delivered page's link; null clears it.
  Future<void> setPageUrl(String orderId, String? url);

  /// Free-text notes; null clears them.
  Future<void> setNotes(String orderId, String? notes);

  /// Saves a new order and returns it as stored. Throws
  /// [DuplicateOrderCode] if the code is already taken.
  Future<Order> create(OrderDraft draft);
}

class DuplicateOrderCode implements Exception {
  const DuplicateOrderCode(this.code);
  final String code;
}
