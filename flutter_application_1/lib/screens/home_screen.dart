import 'package:flutter/material.dart';
import '../app/transaction_provider.dart';
import '../app/settings_provider.dart';
import '../data/settings_store.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onSetGoal,
    this.onViewBudget,
    this.onOpenChat,
  });

  final VoidCallback? onSetGoal;
  final VoidCallback? onViewBudget;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    final store = TransactionProvider.of(context);
    final settingsStore = SettingsProvider.of(context);
    final currencySymbol = settingsStore.currencySymbol;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: ListenableBuilder(
        listenable: Listenable.merge([store, settingsStore]),
        builder: (context, _) {
          final spent = store.spentThisMonth;
          final budget = store.monthlyBudget;
          final hasBudget = store.hasBudgetSet;
          final effectiveIncome = settingsStore.effectiveMonthlyIncome;
          final remaining = (hasBudget && budget > 0 ? budget : effectiveIncome) - spent;
          final byCategory = store.spentByCategoryThisMonth;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCard(
                          remaining: remaining,
                          budget: budget,
                          hasBudget: hasBudget,
                          currencySymbol: currencySymbol,
                        ),
                        const SizedBox(height: 20),
                        _IncomeCard(
                          settingsStore: settingsStore,
                          currencySymbol: currencySymbol,
                        ),
                        const SizedBox(height: 24),
                        const _SectionLabel('Where your money went'),
                        const SizedBox(height: 10),
                        _SpendingSnapshot(byCategory: byCategory),
                        const SizedBox(height: 24),
                        const _SectionLabel('Quick actions'),
                        const SizedBox(height: 12),
                        _QuickActionButton(
                          label: 'Add Expense',
                          icon: Icons.add_circle_outline_rounded,
                          onTap: () => _openAddExpense(context),
                        ),
                        const SizedBox(height: 10),
                        _QuickActionButton(
                          label: 'Set a Goal',
                          icon: Icons.flag_rounded,
                          onTap: () => onSetGoal?.call(),
                        ),
                        const SizedBox(height: 10),
                        _QuickActionButton(
                          label: 'View Budget',
                          icon: Icons.account_balance_wallet_rounded,
                          onTap: () => onViewBudget?.call(),
                        ),
                        const SizedBox(height: 24),
                        _AIInsightCard(
                          remaining: remaining,
                          budget: budget,
                          hasBudget: hasBudget,
                          byCategory: byCategory,
                          spent: spent,
                          onTap: () => onOpenChat?.call(),
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _openAddExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(
          initialType: TransactionType.expense,
        ),
      ),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  final SettingsStore settingsStore;
  final String currencySymbol;

  const _IncomeCard({
    required this.settingsStore,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final effective = settingsStore.effectiveMonthlyIncome;
    final hasPay = settingsStore.payAmount > 0;
    String subtitle;
    if (hasPay) {
      final freq = settingsStore.payFrequency;
      final f = freq == 'weekly' ? 'week' : freq == 'biweekly' ? '2 weeks' : 'month';
      subtitle = '${currencySymbol}${settingsStore.payAmount.toStringAsFixed(0)} per $f';
    } else {
      subtitle = 'Tap to add your income & pay frequency';
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showIncomeDialog(context, settingsStore, currencySymbol),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payments_rounded, color: Color(0xFF2E7D32), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your income',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$currencySymbol${effective.toStringAsFixed(0)} / month',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  static void _showIncomeDialog(BuildContext context, SettingsStore store, String currencySymbol) {
    final amountController = TextEditingController(
      text: store.payAmount > 0 ? store.payAmount.toStringAsFixed(0) : '',
    );
    var frequency = store.payFrequency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Your income'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We\'ll use your default monthly income from Profile unless you set pay below.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount per pay',
                  prefixText: '$currencySymbol ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('How often do you get paid?', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: frequency,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'biweekly', child: Text('Every 2 weeks')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (v) => setState(() => frequency = v ?? 'monthly'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.'));
                if (amount != null && amount > 0) {
                  store.setPay(amount, frequency);
                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double remaining;
  final double budget;
  final bool hasBudget;
  final String currencySymbol;

  const _HeroCard({
    required this.remaining,
    required this.budget,
    required this.hasBudget,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final statusMessage = _statusMessage(remaining, budget, hasBudget);
    final isPositive = remaining >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? [
                  const Color(0xFF2E7D32),
                  const Color(0xFF1B5E20),
                ]
              : [
                  const Color(0xFFB71C1C),
                  const Color(0xFF8B0000),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C))
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentMonth(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining >= 0
                ? '$currencySymbol${_formatAmount(remaining)} left'
                : 'Over by $currencySymbol${_formatAmount(-remaining)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusMessage,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _currentMonth() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[DateTime.now().month - 1];
  }

  static String _statusMessage(double remaining, double budget, bool hasBudget) {
    if (hasBudget && budget > 0) {
      if (remaining < 0) return "You're over budget";
      if (remaining < budget * 0.15) return "You're close to your limit";
      return "You're on track";
    }
    if (remaining >= 0) return "You're on track";
    return "Spending more than income";
  }

  static String _formatAmount(double v) {
    final abs = v.abs();
    if (abs >= 1000) {
      return abs.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return abs.toStringAsFixed(0);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }
}

class _SpendingSnapshot extends StatelessWidget {
  final Map<String, double> byCategory;

  const _SpendingSnapshot({required this.byCategory});

  static const _maxBars = 4;
  static const _barColors = [
    Color(0xFF2E7D32),
    Color(0xFF5AC8FA),
    Color(0xFFFF9500),
    Color(0xFFAF52DE),
  ];

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No spending this month yet',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(_maxBars).toList();
    final total = top.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(top.length, (i) {
          final e = top[i];
          final pct = e.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '${(pct * 100).round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _barColors[i % _barColors.length],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2E7D32),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AIInsightCard extends StatelessWidget {
  final double remaining;
  final double budget;
  final bool hasBudget;
  final Map<String, double> byCategory;
  final double spent;
  final VoidCallback? onTap;

  const _AIInsightCard({
    required this.remaining,
    required this.budget,
    required this.hasBudget,
    required this.byCategory,
    required this.spent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final message = _buildInsightMessage();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE8F5E9),
                const Color(0xFFC8E6C9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tip from your finance coach',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to chat with your AI coach →',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildInsightMessage() {
    if (byCategory.isEmpty && spent == 0) {
      return "You haven't logged any spending yet. Add an expense to get personalised tips.";
    }
    if (hasBudget && budget > 0 && remaining < 0) {
      return "You're over budget this month. Chat with me for ideas to get back on track.";
    }
    if (hasBudget && budget > 0 && remaining < budget * 0.2 && remaining >= 0) {
      return "You're close to your budget limit. Want tips to save without sacrificing too much?";
    }
    final topCategory = byCategory.entries.isNotEmpty
        ? byCategory.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
          )
        : null;
    if (topCategory != null) {
      final pct = byCategory.values.fold(0.0, (a, b) => a + b) > 0
          ? (topCategory.value /
                  byCategory.values.fold(0.0, (a, b) => a + b) * 100)
              .round()
          : 0;
      if (pct >= 40) {
        return "Most of your spending is on ${topCategory.key} this month. Want tips to save?";
      }
    }
    if (remaining >= 0) {
      return "You're on track this month. Keep it up! Ask me if you want to set a goal or save more.";
    }
    return "Need help understanding your spending? Chat with me for friendly advice.";
  }
}
