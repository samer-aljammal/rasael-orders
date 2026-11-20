/// Where an order is in the pipeline. The order follows how Rasael works:
/// the customer pays *after* seeing the preview (docs/DESIGN.md §2).
///
/// A stage is a label, never a colour. Colour comes from [Attention].
enum OrderStatus {
  newOrder('new', 'جديد', 'وصل الطلب، لسا ما بلّشنا'),
  inProgress('in_progress', 'قيد التنفيذ', 'عم نشتغل عالصفحة'),
  previewSent('preview_sent', 'بانتظار الدفع', 'المعاينة عند الزبون'),
  paid('paid', 'مدفوع', 'جاهز للتسليم'),
  delivered('delivered', 'تم التسليم', 'الرابط وصل'),
  cancelled('cancelled', 'ملغى', 'ما كمل');

  const OrderStatus(this.id, this.label, this.hint);

  /// Database value (the `order_status` enum in Postgres).
  final String id;
  final String label;
  final String hint;

  /// Stages shown as tabs, in pipeline order.
  static const pipeline = [newOrder, inProgress, previewSent, paid, delivered];

  bool get isOpen => this != delivered && this != cancelled;

  /// The stage a single "move forward" tap leads to, or null at the end.
  OrderStatus? get next => switch (this) {
    newOrder => inProgress,
    inProgress => previewSent,
    previewSent => paid,
    paid => delivered,
    delivered || cancelled => null,
  };

  /// One step back, to undo a mistaken tap. Cancelled orders reopen as new.
  OrderStatus? get previous => switch (this) {
    newOrder => null,
    inProgress => newOrder,
    previewSent => inProgress,
    paid => previewSent,
    delivered => paid,
    cancelled => newOrder,
  };

  /// The verb on the button that moves an order out of this stage.
  String? get nextAction => switch (this) {
    newOrder => 'بلّش الشغل',
    inProgress => 'أرسلت المعاينة',
    previewSent => 'وصل الدفع',
    paid => 'سلّمت الرابط',
    delivered || cancelled => null,
  };

  static OrderStatus fromId(String id) => OrderStatus.values.firstWhere(
    (s) => s.id == id,
    orElse: () => throw FormatException('Unknown order status: $id'),
  );
}
