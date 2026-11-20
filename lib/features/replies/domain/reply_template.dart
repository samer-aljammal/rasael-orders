import 'package:equatable/equatable.dart';

import '../../orders/domain/order.dart';
import '../../orders/domain/order_status.dart';

/// A saved reply, the way it is typed into WhatsApp again and again, with
/// gaps the app fills from the order: «بتحوّل {السعر} على شام كاش…».
class ReplyTemplate extends Equatable {
  const ReplyTemplate({
    required this.id,
    required this.title,
    required this.body,
    this.stage,
    this.sort = 0,
  });

  final String id;
  final String title;
  final String body;

  /// The stage an order is at when this reply is the one to send.
  /// Null means general: offered at every stage.
  final OrderStatus? stage;
  final int sort;

  ReplyTemplate copyWith({
    String? title,
    String? body,
    OrderStatus? Function()? stage,
    int? sort,
  }) => ReplyTemplate(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    stage: stage != null ? stage() : this.stage,
    sort: sort ?? this.sort,
  );

  @override
  List<Object?> get props => [id, title, body, stage, sort];
}

/// The gaps a reply can contain, and what fills them.
enum ReplyField {
  customer('{الزبون}', 'اسم الزبون'),
  recipient('{لمين}', 'لمين الهدية'),
  price('{السعر}', 'السعر'),
  link('{الرابط}', 'رابط الصفحة'),
  code('{الكود}', 'كود الطلب'),
  kind('{المناسبة}', 'المناسبة');

  const ReplyField(this.token, this.label);

  final String token;
  final String label;
}

/// The result of filling a reply for one order.
class FilledReply {
  const FilledReply(this.text, this.missing);

  final String text;

  /// Fields the reply uses but the order doesn't have yet (e.g. no link
  /// before delivery). The gap stays visible as «[…]» so it can't be sent
  /// by accident.
  final List<ReplyField> missing;

  bool get complete => missing.isEmpty;
}

abstract final class ReplyFill {
  static const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

  /// «١٬٥٠٠ ل.س», written the way the customer messages are: Arabic-Indic
  /// digits and the Arabic thousands separator.
  static String price(int syp) {
    final s = syp.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('٬');
      buf.write(_arabicDigits[s.codeUnitAt(i) - 48]);
    }
    return '$buf ل.س';
  }

  static String? valueFor(ReplyField f, Order o) => switch (f) {
    ReplyField.customer => o.customerName,
    ReplyField.recipient => o.recipientName,
    ReplyField.price => price(o.priceSyp),
    ReplyField.link => o.pageUrl,
    ReplyField.code => o.code,
    ReplyField.kind => o.kind.label,
  };

  static FilledReply fill(ReplyTemplate t, Order o) {
    var text = t.body;
    final missing = <ReplyField>[];
    for (final f in ReplyField.values) {
      if (!text.contains(f.token)) continue;
      final v = valueFor(f, o);
      if (v == null || v.trim().isEmpty) {
        missing.add(f);
        text = text.replaceAll(f.token, '[${f.label}]');
      } else {
        text = text.replaceAll(f.token, v);
      }
    }
    return FilledReply(text, missing);
  }

  /// Replies for an order at its current stage first, then the general ones.
  static List<ReplyTemplate> forStage(
    List<ReplyTemplate> all,
    OrderStatus stage,
  ) {
    final matching = all.where((t) => t.stage == stage).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
    final general = all.where((t) => t.stage == null).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
    return [...matching, ...general];
  }
}
