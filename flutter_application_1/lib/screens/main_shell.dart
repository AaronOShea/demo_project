import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onSetGoal: () => setState(() => _currentIndex = 3),
        onViewBudget: () => setState(() => _currentIndex = 1),
        onOpenChat: () => setState(() => _currentIndex = 2),
      ),
      const BudgetScreen(),
      const ChatScreen(),
      const GoalsScreen(),
      ProfileScreen(onNavigateToGoals: () => setState(() => _currentIndex = 3)),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1C1C1E),
          selectedItemColor: const Color(0xFFAF52DE),
          unselectedItemColor: Colors.white.withValues(alpha: 0.5),
          items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_rounded),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        ),
      ),
    );
  }
}
