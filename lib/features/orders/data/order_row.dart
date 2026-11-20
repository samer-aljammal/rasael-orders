import '../domain/gift_kind.dart';
import '../domain/order.dart';
import '../domain/order_status.dart';

/// Maps between [Order] and a row of `public.orders`
/// (supabase/migrations/20261120000000_init.sql).
///
/// Kept apart from the repository so the mapping is unit-tested without a
/// network.
abstract final class OrderRow {
  static Order fromRow(Map<String, dynamic> r) {
    DateTime? time(String key) {
      final v = r[key];
      return v == null ? null : DateTime.parse(v as String).toLocal();
    }

    final details = (r['details'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(OrderDetail.fromJson)
        .toList(growable: false);

    return Order(
      id: r['id'] as String,
      code: r['code'] as String,
      kind: GiftKind.fromId(r['kind'] as String?),
      packageName: r['package_name'] as String,
      priceSyp: (r['price_syp'] as num).toInt(),
      status: OrderStatus.fromId(r['status'] as String),
      customerName: r['customer_name'] as String,
      customerWhatsapp: r['customer_whatsapp'] as String?,
      customerInstagram: r['customer_instagram'] as String?,
      senderName: r['sender_name'] as String?,
      recipientName: r['recipient_name'] as String?,
      deadline: time('deadline'),
      details: details,
      hasPhotos: r['has_photos'] as bool? ?? false,
      wantsMusic: r['wants_music'] as bool? ?? false,
      notes: r['notes'] as String?,
      pageUrl: r['page_url'] as String?,
      previewUrl: r['preview_url'] as String?,
      createdAt: time('created_at')!,
      updatedAt: time('updated_at')!,
      previewSentAt: time('preview_sent_at'),
      paidAt: time('paid_at'),
      deliveredAt: time('delivered_at'),
    );
  }

  /// The writable columns. Ids, owner and timestamps are set by Postgres.
  static Map<String, dynamic> toInsert(Order o) => {
    'code': o.code,
    'kind': o.kind.id,
    'package_name': o.packageName,
    'price_syp': o.priceSyp,
    'status': o.status.id,
    'customer_name': o.customerName,
    'customer_whatsapp': o.customerWhatsapp,
    'customer_instagram': o.customerInstagram,
    'sender_name': o.senderName,
    'recipient_name': o.recipientName,
    'deadline': o.deadline?.toUtc().toIso8601String(),
    'details': o.details.map((d) => d.toJson()).toList(),
    'has_photos': o.hasPhotos,
    'wants_music': o.wantsMusic,
    'notes': o.notes,
    'page_url': o.pageUrl,
    'preview_url': o.previewUrl,
  };
}
