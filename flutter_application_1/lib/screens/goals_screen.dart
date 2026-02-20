import 'package:flutter/material.dart';
import '../app/goals_provider.dart';
import '../app/settings_provider.dart';
import '../app/transaction_provider.dart';
import '../data/goals_store.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsStore = GoalsProvider.of(context);
    final settingsStore = SettingsProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: goalsStore,
          builder: (context, _) {
            final goals = goalsStore.goals;
            final hasGoals = goals.isNotEmpty;
            final primaryGoal = goalsStore.primaryGoal;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              _SavingsJarHero(),
                              const SizedBox(height: 20),
                              Text(
                                'Set a goal. Save for it. Get there.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade800,
                                  height: 1.3,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Every amount you put in gets you closer.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasGoals) ...[
                          const SizedBox(height: 24),
                          _TeaserCards(
                            onAddGoal: () => _showAddGoalDialog(context, goalsStore),
                            onQuickDeposit: primaryGoal != null
                                ? () => _showAddSavingsDialog(
                                      context,
                                      goalsStore,
                                      primaryGoal,
                                      settingsStore.currencySymbol,
                                    )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!hasGoals)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No goals yet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the button below to add your first goal',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final goal = goals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GoalCard(
                              goal: goal,
                              currencySymbol: settingsStore.currencySymbol,
                              onSetPrimary: () => goalsStore.setPrimary(goal.id),
                              onMarkCompleted: () => goalsStore.markCompleted(goal.id),
                              onAddSavings: () => _showAddSavingsDialog(
                                context,
                                goalsStore,
                                goal,
                                settingsStore.currencySymbol,
                              ),
                              onRemove: () => _confirmRemoveGoal(context, goalsStore, goal),
                            ),
                          );
                        },
                        childCount: goals.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, GoalsProvider.of(context)),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add goal'),
      ),
    );
  }

  Future<void> _showAddGoalDialog(BuildContext context, GoalsStore goalsStore) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    var setAsPrimary = true;

    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Goal name',
                        hintText: 'e.g. Emergency fund',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Target amount',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: setAsPrimary,
                      onChanged: (v) => setDialogState(() => setAsPrimary = v ?? true),
                      title: const Text('Set as primary goal'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: () {
                    final title = titleController.text.trim();
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', '.'),
                    );
                    if (title.isEmpty) return;
                    if (amount == null || amount <= 0) return;
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;
    final title = titleController.text.trim();
    final amount = double.tryParse(
      amountController.text.trim().replaceAll(',', '.'),
    );
    if (title.isEmpty || amount == null || amount <= 0) return;
    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      targetAmount: amount,
      isPrimary: setAsPrimary,
      createdAt: DateTime.now(),
    );
    goalsStore.addGoal(goal);
  }

  Future<void> _showAddSavingsDialog(
    BuildContext context,
    GoalsStore goalsStore,
    Goal goal,
    String currencySymbol,
  ) async {
    final maxAdd = goal.targetAmount - goal.savedAmount;
    if (maxAdd <= 0) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Goal reached!'),
          content: Text(
            'You\'ve already reached your target for "${goal.title}". You can\'t add more.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final controller = TextEditingController();

    if (!context.mounted) return;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to "${goal.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: $currencySymbol${goal.savedAmount.toStringAsFixed(0)} / $currencySymbol${goal.targetAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Max you can add: $currencySymbol${maxAdd.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Amount to add',
                prefixText: '$currencySymbol ',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              final amount = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (amount != null && amount > 0) Navigator.of(context).pop(amount);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result > 0 && context.mounted) {
      final actualAdded = goalsStore.addToSavedAmount(goal.id, result);
      if (actualAdded > 0) {
        final transactionStore = TransactionProvider.of(context);
        transactionStore.addTransaction(
          Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: actualAdded,
            type: TransactionType.expense,
            category: 'Savings',
            date: DateTime.now(),
            note: 'Goal: ${goal.title}',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $currencySymbol${actualAdded.toStringAsFixed(0)} to ${goal.title}'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        final updated = goalsStore.goals.where((g) => g.id == goal.id).firstOrNull;
        if (updated != null && updated.isCompleted) {
          _showCongratsDialog(context, goal.title);
        }
      }
    }
  }

  void _showCongratsDialog(BuildContext context, String goalTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.celebration_rounded, color: Colors.green.shade700, size: 32),
            const SizedBox(width: 12),
            const Expanded(child: Text('Congratulations!')),
          ],
        ),
        content: Text(
          'You\'ve reached your goal: "$goalTitle". Well done!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveGoal(
    BuildContext context,
    GoalsStore goalsStore,
    Goal goal,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove goal'),
        content: Text('Remove "${goal.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Color(0xFFB71C1C))),
          ),
        ],
      ),
    );
    if (ok == true) goalsStore.removeGoal(goal.id);
  }
}

class _SavingsJarHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.savings_rounded,
        size: 72,
        color: Colors.green.shade700,
      ),
    );
  }
}

class _TeaserCards extends StatelessWidget {
  final VoidCallback onAddGoal;
  final VoidCallback? onQuickDeposit;

  const _TeaserCards({
    required this.onAddGoal,
    this.onQuickDeposit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TeaserCard(
            icon: Icons.add_rounded,
            label: 'New goal',
            onTap: onAddGoal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TeaserCard(
            icon: Icons.add_circle_outline_rounded,
            label: onQuickDeposit != null ? 'Quick deposit' : 'New goal',
            onTap: onQuickDeposit ?? onAddGoal,
          ),
        ),
      ],
    );
  }
}

class _TeaserCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TeaserCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: const Color(0xFF2E7D32)),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final String currencySymbol;
  final VoidCallback onSetPrimary;
  final VoidCallback onMarkCompleted;
  final VoidCallback onAddSavings;
  final VoidCallback onRemove;

  const _GoalCard({
    required this.goal,
    required this.currencySymbol,
    required this.onSetPrimary,
    required this.onMarkCompleted,
    required this.onAddSavings,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = goal.isCompleted;

    return Card(
      elevation: 0,
      color: isComplete ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isComplete
              ? const Color(0xFF2E7D32)
              : goal.isPrimary
                  ? const Color(0xFF2E7D32)
                  : Colors.grey.shade200,
          width: isComplete || goal.isPrimary ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isComplete)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.celebration_rounded, size: 20, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Congratulations! Goal reached.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.green.shade100 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.savings_rounded,
                    size: 24,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          decoration: isComplete ? TextDecoration.lineThrough : null,
                          color: isComplete ? Colors.grey.shade700 : Colors.grey.shade800,
                        ),
                      ),
                      if (goal.isPrimary)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Primary goal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isComplete)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 28)
                else
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
                    onSelected: (_) => onRemove(),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Color(0xFFB71C1C), size: 20),
                            SizedBox(width: 12),
                            Text('Remove goal', style: TextStyle(color: Color(0xFFB71C1C))),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currencySymbol${goal.savedAmount.toStringAsFixed(0)} / $currencySymbol${goal.targetAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (!isComplete)
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            ),
            if (!isComplete) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAddSavings,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add savings'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!goal.isPrimary)
                    TextButton.icon(
                      onPressed: onSetPrimary,
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('Primary'),
                    ),
                  TextButton.icon(
                    onPressed: onMarkCompleted,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Done'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
