import 'order.dart';
import 'order_status.dart';

/// The one boundary between the app and wherever orders live.
///
/// Two implementations: Supabase (real orders, realtime) and an in-memory
/// demo seeded with fictional orders. Screens never know which one they have.
abstract interface class OrderRepository {
  /// Every order, newest first, re-emitted whenever anything changes —
  /// including changes made from another device.
  Stream<List<Order>> watchOrders();

  Future<void> moveTo(String orderId, OrderStatus status);
}
