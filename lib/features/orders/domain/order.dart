import 'package:equatable/equatable.dart';

import 'gift_kind.dart';
import 'order_source.dart';
import 'order_status.dart';

/// One answer from the order form, kept in the order the form asked it.
class OrderDetail extends Equatable {
  const OrderDetail(this.label, this.value);

  final String label;
  final String value;

  Map<String, String> toJson() => {'label': label, 'value': value};

  factory OrderDetail.fromJson(Map<String, dynamic> json) =>
      OrderDetail(json['label'] as String, json['value'] as String);

  @override
  List<Object?> get props => [label, value];
}

/// What needs doing about an order, if anything. The whole colour
/// vocabulary of the app (docs/DESIGN.md §2).
enum Attention {
  late('متأخر'),
  dueToday('اليوم'),
  followUp('تابع الدفع');

  const Attention(this.label);
  final String label;
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.code,
    required this.kind,
    required this.packageName,
    required this.priceSyp,
    required this.status,
    required this.customerName,
    required this.createdAt,
    required this.updatedAt,
    this.customerWhatsapp,
    this.customerInstagram,
    this.senderName,
    this.recipientName,
    this.source,
    this.paymentMethod,
    this.deadline,
    this.details = const [],
    this.hasPhotos = false,
    this.wantsMusic = false,
    this.notes,
    this.pageUrl,
    this.previewUrl,
    this.previewSentAt,
    this.paidAt,
    this.deliveredAt,
  });

  final String id;

  /// The «R-XXXXX» code the order form generates.
  final String code;
  final GiftKind kind;
  final String packageName;

  /// Whole Syrian pounds. Stored as an integer; never a double for money.
  final int priceSyp;
  final OrderStatus status;

  final String customerName;
  final String? customerWhatsapp;
  final String? customerInstagram;

  /// The names as they appear on the page («من» and «لـ»).
  final String? senderName;
  final String? recipientName;

  /// Null for orders imported from before the app recorded it.
  final OrderSource? source;
  final PaymentMethod? paymentMethod;

  final DateTime? deadline;
  final List<OrderDetail> details;
  final bool hasPhotos;
  final bool wantsMusic;
  final String? notes;
  final String? pageUrl;
  final String? previewUrl;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? previewSentAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;

  /// How long an unpaid preview can sit before it's worth a nudge.
  static const followUpAfter = Duration(hours: 48);

  /// «لين ← سامي», or the customer's name when the page has no names yet.
  String get headline {
    if (senderName != null && recipientName != null) {
      return '$senderName ← $recipientName';
    }
    return recipientName ?? customerName;
  }

  Attention? attentionAt(DateTime now) {
    if (!status.isOpen) return null;
    final d = deadline;
    if (d != null) {
      if (d.isBefore(now)) return Attention.late;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        return Attention.dueToday;
      }
    }
    final sent = previewSentAt;
    if (status == OrderStatus.previewSent &&
        sent != null &&
        now.difference(sent) > followUpAfter) {
      return Attention.followUp;
    }
    return null;
  }

  Order copyWith({
    OrderStatus? status,
    DateTime? updatedAt,
    DateTime? previewSentAt,
    DateTime? paidAt,
    DateTime? deliveredAt,
  }) => Order(
    id: id,
    code: code,
    kind: kind,
    packageName: packageName,
    priceSyp: priceSyp,
    status: status ?? this.status,
    customerName: customerName,
    customerWhatsapp: customerWhatsapp,
    customerInstagram: customerInstagram,
    senderName: senderName,
    recipientName: recipientName,
    source: source,
    paymentMethod: paymentMethod,
    deadline: deadline,
    details: details,
    hasPhotos: hasPhotos,
    wantsMusic: wantsMusic,
    notes: notes,
    pageUrl: pageUrl,
    previewUrl: previewUrl,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    previewSentAt: previewSentAt ?? this.previewSentAt,
    paidAt: paidAt ?? this.paidAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
  );

  /// Applies a stage change the same way the database trigger does, so the
  /// demo repository and Supabase agree on every timestamp.
  Order movedTo(OrderStatus next, DateTime at) => copyWith(
    status: next,
    updatedAt: at,
    previewSentAt: next == OrderStatus.previewSent ? at : null,
    paidAt: next == OrderStatus.paid && paidAt == null ? at : null,
    deliveredAt: next == OrderStatus.delivered ? at : null,
  );

  @override
  List<Object?> get props => [id, status, updatedAt];
}

/// A new order before it has an id or timestamps: what quick add collects.
class OrderDraft {
  const OrderDraft({
    required this.code,
    required this.kind,
    required this.packageName,
    required this.priceSyp,
    required this.customerName,
    required this.source,
    this.customerWhatsapp,
    this.customerInstagram,
    this.senderName,
    this.recipientName,
    this.deadline,
    this.notes,
  });

  final String code;
  final GiftKind kind;
  final String packageName;
  final int priceSyp;
  final String customerName;
  final OrderSource source;
  final String? customerWhatsapp;
  final String? customerInstagram;
  final String? senderName;
  final String? recipientName;
  final DateTime? deadline;
  final String? notes;

  /// The order as it exists the moment it is saved.
  Order toOrder({required String id, required DateTime at}) => Order(
    id: id,
    code: code,
    kind: kind,
    packageName: packageName,
    priceSyp: priceSyp,
    status: OrderStatus.newOrder,
    customerName: customerName,
    customerWhatsapp: customerWhatsapp,
    customerInstagram: customerInstagram,
    senderName: senderName,
    recipientName: recipientName,
    source: source,
    deadline: deadline,
    notes: notes,
    createdAt: at,
    updatedAt: at,
  );
}

