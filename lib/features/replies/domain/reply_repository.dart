import '../../orders/domain/order_status.dart';
import 'reply_template.dart';

/// Saved replies. A new account starts with the studio's default set
/// (see `default_replies.dart`), which it is then free to edit.
abstract interface class ReplyRepository {
  /// Sorted by stage order, then by [ReplyTemplate.sort].
  Stream<List<ReplyTemplate>> watch();

  Future<void> add({
    required String title,
    required String body,
    OrderStatus? stage,
  });

  Future<void> update(ReplyTemplate template);

  Future<void> delete(String id);
}
