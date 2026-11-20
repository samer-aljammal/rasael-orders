import 'dart:async';

import '../domain/order.dart';
import '../domain/order_repository.dart';
import '../domain/order_status.dart';
import 'demo_seed.dart';

/// In-memory orders for the public demo and for running without a backend.
///
/// Behaves like the Supabase repository from the screen's point of view: a
/// stream that re-emits on every change, with the same timestamp rules
/// ([Order.movedTo] mirrors the database trigger).
class DemoOrderRepository implements OrderRepository {
  DemoOrderRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  late List<Order> _orders = DemoSeed.orders(_clock());
  final _changes = StreamController<List<Order>>.broadcast();

  /// Simulated round trip, so loading states are exercised in the demo too.
  static const _latency = Duration(milliseconds: 350);

  @override
  Stream<List<Order>> watchOrders() async* {
    await Future<void>.delayed(_latency);
    yield _sorted();
    yield* _changes.stream;
  }

  @override
  Future<void> moveTo(String orderId, OrderStatus status) async {
    _orders = [
      for (final o in _orders)
        o.id == orderId ? o.movedTo(status, _clock()) : o,
    ];
    _changes.add(_sorted());
  }

  /// Starts the demo over with fresh, current-dated orders.
  void reset() {
    _orders = DemoSeed.orders(_clock());
    _changes.add(_sorted());
  }

  List<Order> _sorted() =>
      [..._orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
