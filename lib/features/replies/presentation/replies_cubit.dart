import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../orders/domain/order_status.dart';
import '../domain/reply_repository.dart';
import '../domain/reply_template.dart';

/// Null while loading; otherwise the current saved replies.
class RepliesCubit extends Cubit<List<ReplyTemplate>?> {
  RepliesCubit(this._repo) : super(null) {
    _sub = _repo.watch().listen(
      emit,
      // Replies are a convenience: if they fail to load, the order screen
      // simply shows none rather than an error.
      onError: (Object _) => emit(const []),
    );
  }

  final ReplyRepository _repo;
  StreamSubscription<List<ReplyTemplate>>? _sub;

  Future<void> add(String title, String body, OrderStatus? stage) =>
      _repo.add(title: title.trim(), body: body.trim(), stage: stage);

  Future<void> save(ReplyTemplate t) => _repo.update(t);

  Future<void> delete(ReplyTemplate t) => _repo.delete(t.id);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
