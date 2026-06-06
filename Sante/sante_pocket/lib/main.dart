import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/identity/identite_screen.dart';
import 'features/identity/edit_identite_screen.dart';
import 'features/emergency/urgences_screen.dart';
import 'features/documents/vaccins_screen.dart';
import 'features/documents/symptomes_screen.dart';
import 'features/documents/documents_screen.dart';
import 'features/sync/sync_screen.dart';
import 'features/sync/p2p_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/identite',
      builder: (context, state) => const IdentiteScreen(),
    ),
    GoRoute(
      path: '/edit-identite',
      builder: (context, state) => const EditIdentiteScreen(),
    ),
    GoRoute(
      path: '/urgences',
      builder: (context, state) => const UrgencesScreen(),
    ),
    GoRoute(
      path: '/vaccins',
      builder: (context, state) => const VaccinsScreen(),
    ),
    GoRoute(
      path: '/symptomes',
      builder: (context, state) => const SymptomesScreen(),
    ),
    GoRoute(
      path: '/documents',
      builder: (context, state) => const DocumentsScreen(),
    ),
    GoRoute(
      path: '/sync',
      builder: (context, state) => const SyncScreen(),
    ),
    GoRoute(
      path: '/p2p',
      builder: (context, state) => const P2PScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Santé Pocket',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      // Localisation française pour le DatePicker et autres widgets Material
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
