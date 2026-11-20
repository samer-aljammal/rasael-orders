import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injector.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_cubit.dart';

class RasaelOrdersApp extends StatefulWidget {
  const RasaelOrdersApp({super.key});

  @override
  State<RasaelOrdersApp> createState() => _RasaelOrdersAppState();
}

class _RasaelOrdersAppState extends State<RasaelOrdersApp> {
  late final AuthCubit _auth = AuthCubit(authRepositoryOrNull);
  late final GoRouter _router = buildRouter(_auth);

  @override
  void dispose() {
    _router.dispose();
    _auth.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _auth,
      child: MaterialApp.router(
        title: 'رسائل · الطلبات',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        // Arabic only, so Material lays everything out right-to-left and
        // its built-in strings (tooltips, date pickers) are Arabic too.
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router,
      ),
    );
  }
}
