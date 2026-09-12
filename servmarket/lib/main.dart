import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/search_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ServMarketApp());
}

class ServMarketApp extends StatelessWidget {
  const ServMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider.instance..init()),
        ChangeNotifierProvider(create: (_) => SearchProvider.instance),
      ],
      child: const MaterialApp(
        title: 'ServMarket',
        debugShowCheckedModeBanner: false,
        home: AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isOnboardingChecked = false;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (mounted) {
      setState(() {
        _onboardingCompleted = completed;
        _isOnboardingChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnboardingChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading && !auth.isAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        if (!_onboardingCompleted) {
          return const OnboardingScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
