import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/order.dart';
import '../domain/order_repository.dart';
import '../domain/order_source.dart';
import '../domain/order_status.dart';
import 'order_row.dart';

/// Orders in Supabase Postgres. Row-level security limits every query to
/// the signed-in owner, so nothing here filters by user.
class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'orders';

  @override
  Stream<List<Order>> watchOrders() => _client
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(OrderRow.fromRow).toList(growable: false));

  /// Only the status is sent. The `orders_touch` trigger stamps
  /// `updated_at`, `preview_sent_at`, `paid_at` and `delivered_at`, and
  /// writes the history row, so two devices can never disagree on them.
  @override
  Future<void> moveTo(
    String orderId,
    OrderStatus status, {
    PaymentMethod? paidWith,
  }) => _client
      .from(_table)
      .update({
        'status': status.id,
        if (paidWith != null) 'payment_method': paidWith.id,
      })
      .eq('id', orderId);

  @override
  Future<void> setPageUrl(String orderId, String? url) =>
      _client.from(_table).update({'page_url': url}).eq('id', orderId);

  @override
  Future<void> setNotes(String orderId, String? notes) =>
      _client.from(_table).update({'notes': notes}).eq('id', orderId);

  @override
  Future<Order> create(OrderDraft draft) async {
    try {
      final row = await _client
          .from(_table)
          .insert(OrderRow.fromDraft(draft))
          .select()
          .single();
      return OrderRow.fromRow(row);
    } on PostgrestException catch (e) {
      // 23505: unique_violation on (owner_id, code).
      if (e.code == '23505') throw DuplicateOrderCode(draft.code);
      rethrow;
    }
  }
}
