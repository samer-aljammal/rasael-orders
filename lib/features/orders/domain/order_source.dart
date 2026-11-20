/// The channel an order arrived through.
///
/// Most orders now start as a chat from the Instagram bio page, so this is
/// what tells the dashboard whether that page is working.
enum OrderSource {
  whatsapp('whatsapp', 'واتساب'),
  instagram('instagram', 'إنستا'),
  form('form', 'الفورم'),
  other('other', 'غير شي');

  const OrderSource(this.id, this.label);

  final String id;
  final String label;

  static OrderSource? fromId(String? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// How a customer paid. Set when an order is marked paid.
enum PaymentMethod {
  shamCash('sham_cash', 'شام كاش'),
  syriatelCash('syriatel_cash', 'سيريتل كاش'),
  transfer('transfer', 'حوالة'),
  cash('cash', 'كاش'),
  other('other', 'غير شي');

  const PaymentMethod(this.id, this.label);

  final String id;
  final String label;

  static PaymentMethod? fromId(String? id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return null;
  }
}
