import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/orders/data/demo_order_repository.dart';
import '../../features/orders/data/supabase_order_repository.dart';
import '../../features/orders/domain/order_repository.dart';
import '../../features/replies/data/demo_reply_repository.dart';
import '../../features/replies/data/supabase_reply_repository.dart';
import '../../features/replies/domain/reply_repository.dart';
import '../config/app_config.dart';

final sl = GetIt.instance;

/// Wires the backend. This is the only file that knows Supabase exists;
/// everything else depends on [AuthRepository] and [OrderRepository].
Future<void> configureDependencies() async {
  sl
    ..registerLazySingleton<DemoOrderRepository>(DemoOrderRepository.new)
    ..registerLazySingleton<DemoReplyRepository>(DemoReplyRepository.new);

  if (!AppConfig.hasBackend) return;

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseKey,
  );
  final client = Supabase.instance.client;
  sl
    ..registerSingleton<AuthRepository>(SupabaseAuthRepository(client.auth))
    ..registerLazySingleton<SupabaseOrderRepository>(
      () => SupabaseOrderRepository(client),
    )
    ..registerLazySingleton<SupabaseReplyRepository>(
      () => SupabaseReplyRepository(client),
    );
}

ReplyRepository replyRepositoryFor(AppUser user) => user.isDemo
    ? sl<DemoReplyRepository>()
    : sl<SupabaseReplyRepository>();

AuthRepository? get authRepositoryOrNull =>
    sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : null;

/// Demo sessions get the in-memory orders; real sessions get Supabase.
OrderRepository orderRepositoryFor(AppUser user) => user.isDemo
    ? sl<DemoOrderRepository>()
    : sl<SupabaseOrderRepository>();
