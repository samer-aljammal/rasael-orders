import 'package:supabase_flutter/supabase_flutter.dart';

import '../../orders/domain/order_status.dart';
import '../domain/reply_repository.dart';
import '../domain/reply_template.dart';
import 'default_replies.dart';

/// Saved replies in `public.reply_templates` (RLS: owner only).
class SupabaseReplyRepository implements ReplyRepository {
  SupabaseReplyRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'reply_templates';
  bool _seedChecked = false;

  static ReplyTemplate _fromRow(Map<String, dynamic> r) => ReplyTemplate(
    id: r['id'] as String,
    title: r['title'] as String,
    body: r['body'] as String,
    stage: r['stage'] == null ? null : OrderStatus.fromId(r['stage'] as String),
    sort: (r['sort'] as num?)?.toInt() ?? 0,
  );

  @override
  Stream<List<ReplyTemplate>> watch() async* {
    await _seedIfEmpty();
    yield* _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('sort')
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// A brand-new account gets the default set. Checked once per app start,
  /// so deleting every reply brings the defaults back on the next launch,
  /// which is the useful behaviour for a list nobody wants to be empty.
  Future<void> _seedIfEmpty() async {
    if (_seedChecked) return;
    _seedChecked = true;
    final existing = await _client.from(_table).select('id').limit(1);
    if (existing.isNotEmpty) return;
    await _client.from(_table).insert([
      for (final (i, (title, stage, body)) in defaultReplies.indexed)
        {'title': title, 'body': body, 'stage': stage?.id, 'sort': i * 10},
    ]);
  }

  @override
  Future<void> add({
    required String title,
    required String body,
    OrderStatus? stage,
  }) => _client.from(_table).insert({
    'title': title,
    'body': body,
    'stage': stage?.id,
    // Appended after the defaults.
    'sort': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  });

  @override
  Future<void> update(ReplyTemplate t) => _client
      .from(_table)
      .update({'title': t.title, 'body': t.body, 'stage': t.stage?.id})
      .eq('id', t.id);

  @override
  Future<void> delete(String id) =>
      _client.from(_table).delete().eq('id', id);
}
