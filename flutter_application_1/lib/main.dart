import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'data/transaction_store.dart';
import 'data/settings_store.dart';
import 'data/goals_store.dart';
import 'app/transaction_provider.dart';
import 'app/settings_provider.dart';
import 'app/goals_provider.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AIFC Finance Coach',
            theme: ThemeData(primarySwatch: Colors.green),
            home: const _SplashLoading(),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AIFC Finance Coach',
            theme: ThemeData(primarySwatch: Colors.green),
            home: const LoginScreen(),
          );
        }
        final store = TransactionStore();
        final settingsStore = SettingsStore();
        final goalsStore = GoalsStore();
        return TransactionProvider(
          store: store,
          child: SettingsProvider(
            store: settingsStore,
            child: GoalsProvider(
              store: goalsStore,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'AIFC Finance Coach',
                theme: ThemeData(primarySwatch: Colors.green),
                home: const MainShell(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF1B5E20),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
