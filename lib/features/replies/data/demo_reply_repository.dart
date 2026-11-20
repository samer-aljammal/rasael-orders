import 'dart:async';

import '../../orders/domain/order_status.dart';
import '../domain/reply_repository.dart';
import '../domain/reply_template.dart';
import 'default_replies.dart';

/// In-memory replies for the demo, starting from the default set.
class DemoReplyRepository implements ReplyRepository {
  DemoReplyRepository() {
    _reset();
  }

  late List<ReplyTemplate> _items;
  final _changes = StreamController<List<ReplyTemplate>>.broadcast();
  var _nextId = 1;

  void _reset() {
    _items = [
      for (final (i, (title, stage, body)) in defaultReplies.indexed)
        ReplyTemplate(
          id: 'reply-$i',
          title: title,
          body: body,
          stage: stage,
          sort: i * 10,
        ),
    ];
  }

  void reset() {
    _reset();
    _emit();
  }

  void _emit() => _changes.add(List.unmodifiable(_items));

  @override
  Stream<List<ReplyTemplate>> watch() async* {
    yield List.unmodifiable(_items);
    yield* _changes.stream;
  }

  @override
  Future<void> add({
    required String title,
    required String body,
    OrderStatus? stage,
  }) async {
    _items = [
      ..._items,
      ReplyTemplate(
        id: 'reply-new-${_nextId++}',
        title: title,
        body: body,
        stage: stage,
        sort: 1000 + _nextId,
      ),
    ];
    _emit();
  }

  @override
  Future<void> update(ReplyTemplate t) async {
    _items = [for (final x in _items) x.id == t.id ? t : x];
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items = _items.where((x) => x.id != id).toList();
    _emit();
  }
}
