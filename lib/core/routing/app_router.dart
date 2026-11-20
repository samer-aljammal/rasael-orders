import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/orders/data/demo_order_repository.dart';
import '../../features/orders/presentation/orders_cubit.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../di/injector.dart';

abstract final class Routes {
  static const signIn = '/sign-in';
  static const orders = '/';
}

GoRouter buildRouter(AuthCubit auth) => GoRouter(
  initialLocation: Routes.orders,
  refreshListenable: _StreamListenable(auth.stream),
  redirect: (context, state) {
    final signedIn = auth.state.signedIn;
    final atSignIn = state.matchedLocation == Routes.signIn;
    if (!signedIn) return atSignIn ? null : Routes.signIn;
    if (atSignIn) return Routes.orders;
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.signIn,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SignInScreen()),
    ),
    GoRoute(
      path: Routes.orders,
      pageBuilder: (context, state) {
        final user = auth.state.user!;
        return NoTransitionPage(
          child: BlocProvider(
            // Keyed by user: switching between demo and a real account must
            // never show one session's orders to the other.
            key: ValueKey(user.id),
            create: (_) => OrdersCubit(orderRepositoryFor(user)),
            child: OrdersScreen(
              onResetDemo: user.isDemo ? sl<DemoOrderRepository>().reset : null,
            ),
          ),
        );
      },
    ),
  ],
);

/// Lets go_router re-run its redirect whenever the auth state changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
