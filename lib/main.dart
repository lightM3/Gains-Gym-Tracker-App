import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:gains/screens/home/home_screen.dart';
import 'package:gains/screens/auth/welcome_screen.dart';
import 'package:gains/screens/auth/register_screen.dart';
import 'package:gains/screens/auth/login_screen.dart';
import 'package:gains/providers/auth_provider.dart';
import 'package:gains/services/notification_service.dart';

// Uygulama başlangıcı
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await NotificationService().init();
  runApp(const ProviderScope(child: MyApp()));
}

// Uygulamanın ana widget'ı
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gains',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const HomePage();
          }
          return const WelcomePage();
        },
        loading: () => const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        error: (_, __) => const WelcomePage(),
      ),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
