// Import Firebase core so the app can connect to Firebase services
import 'package:firebase_core/firebase_core.dart';

// Import Flutter material UI components
import 'package:flutter/material.dart';

// Import login screen
import 'auth/login_screen.dart';

// Import data stores (handle data storage)
import 'data/transaction_store.dart';
import 'data/settings_store.dart';
import 'data/goals_store.dart';

// Import providers (used for state management)
import 'app/transaction_provider.dart';
import 'app/settings_provider.dart';
import 'app/goals_provider.dart';

// Import main app screen
import 'screens/main_shell.dart';

// Import authentication service
import 'services/auth_service.dart';

void main() async {
  // Make sure Flutter is fully initialized before running async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Start the app
  runApp(const BudgetApp());
}

// Main app widget
class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to login/logout changes
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {

        // While checking login status, show loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AIFC Finance Coach',
            theme: ThemeData(primarySwatch: Colors.green),
            home: const _SplashLoading(),
          );
        }

        // Get current user
        final user = snapshot.data;

        // If user is NOT logged in → show login screen
        if (user == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AIFC Finance Coach',
            theme: ThemeData(primarySwatch: Colors.green),
            home: const LoginScreen(),
          );
        }

        // If user IS logged in → create data stores
        final store = TransactionStore();
        final settingsStore = SettingsStore();
        final goalsStore = GoalsStore();

        // Wrap app with providers so data is available everywhere
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
                home: const MainShell(), // Main app screen
              ),
            ),
          ),
        );
      },
    );
  }
}

// Simple splash/loading screen widget
class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // Green gradient background
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

        // White loading spinner in the center
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
