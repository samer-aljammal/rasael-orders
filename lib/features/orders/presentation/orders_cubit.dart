import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/order.dart';
import '../domain/order_repository.dart';
import '../domain/order_status.dart';

sealed class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersError extends OrdersState {
  const OrdersError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders, this.now);

  final List<Order> orders;

  /// The moment attention was computed against. Part of the state so the
  /// screen and its tests agree on what "late" means.
  final DateTime now;

  /// Late first, then due today, then follow-ups; oldest deadline first.
  List<Order> get needsAttention {
    final list = orders.where((o) => o.attentionAt(now) != null).toList();
    int rank(Order o) => o.attentionAt(now)!.index;
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      final da = a.deadline ?? a.previewSentAt ?? a.createdAt;
      final db = b.deadline ?? b.previewSentAt ?? b.createdAt;
      return da.compareTo(db);
    });
    return list;
  }

  List<Order> get open => orders.where((o) => o.status.isOpen).toList();

  int countIn(OrderStatus s) => orders.where((o) => o.status == s).length;

  @override
  List<Object?> get props => [orders, now];
}

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repo, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const OrdersLoading()) {
    _listen();
  }

  final OrderRepository _repo;
  final DateTime Function() _clock;
  StreamSubscription<List<Order>>? _sub;

  void _listen() {
    _sub?.cancel();
    _sub = _repo.watchOrders().listen(
      (orders) => emit(OrdersLoaded(orders, _clock())),
      onError: (Object _) => emit(
        const OrdersError('ما قدرنا نجيب الطلبات. تأكد من الإنترنت وجرّب كمان مرة.'),
      ),
    );
  }

  void retry() {
    emit(const OrdersLoading());
    _listen();
  }

  Future<void> moveForward(Order order) async {
    final next = order.status.next;
    if (next == null) return;
    await _repo.moveTo(order.id, next);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
