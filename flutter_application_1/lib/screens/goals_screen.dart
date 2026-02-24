// Flutter UI package
import 'package:flutter/material.dart';

// Providers give access to app data/state (goals, settings, transactions)
import '../app/goals_provider.dart';
import '../app/settings_provider.dart';
import '../app/transaction_provider.dart';

// GoalsStore is the class that actually stores/updates the goals list
import '../data/goals_store.dart';

// Models for goals and transactions
import '../models/goal_model.dart';
import '../models/transaction_model.dart';

// Screen that shows savings goals
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

// State class (Stateful because it uses animations and dialogs)
class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {

  // Controls the fade-in animation
  late AnimationController _fadeController;

  // The fade value (0 -> 1)
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Create the animation controller (how long the animation lasts)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Make the animation curve smooth (ease out)
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Start the fade animation when screen loads
    _fadeController.forward();
  }

  @override
  void dispose() {
    // Clean up animation controller when leaving screen
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Get goals store (list of goals + methods to update them)
    final goalsStore = GoalsProvider.of(context);

    // Get settings store (mainly used here for currency symbol)
    final settingsStore = SettingsProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),

      // Top bar
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(

        // Rebuild the UI whenever goalsStore changes
        child: ListenableBuilder(
          listenable: goalsStore,
          builder: (context, _) {

            // Get all goals
            final goals = goalsStore.goals;

            // True if there is at least 1 goal
            final hasGoals = goals.isNotEmpty;

            // Get the current "primary" goal (if any)
            final primaryGoal = goalsStore.primaryGoal;

            return CustomScrollView(
              slivers: [

                // Header section at the top
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      children: [

                        // Fade-in animation for the hero text + icon
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              _SavingsJarHero(), // big savings icon
                              const SizedBox(height: 20),

                              // Main header text
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

                              // Smaller helper text
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

                        // If goals exist, show two quick action cards
                        if (hasGoals) ...[
                          const SizedBox(height: 24),
                          _TeaserCards(
                            onAddGoal: () => _showAddGoalDialog(context, goalsStore),

                            // Quick deposit only works if there is a primary goal
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

                // If no goals, show an empty-state message
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

                // Otherwise, show the list of goal cards
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {

                          // Get goal at this index
                          final goal = goals[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GoalCard(
                              goal: goal,
                              currencySymbol: settingsStore.currencySymbol,

                              // Make this goal the primary one
                              onSetPrimary: () => goalsStore.setPrimary(goal.id),

                              // Mark as completed
                              onMarkCompleted: () => goalsStore.markCompleted(goal.id),

                              // Open dialog to add money to this goal
                              onAddSavings: () => _showAddSavingsDialog(
                                context,
                                goalsStore,
                                goal,
                                settingsStore.currencySymbol,
                              ),

                              // Confirm and remove the goal
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

      // Bottom-right button to add a goal
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, GoalsProvider.of(context)),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add goal'),
      ),
    );
  }

  // Dialog to add a new goal (name + target amount + primary checkbox)
  Future<void> _showAddGoalDialog(BuildContext context, GoalsStore goalsStore) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    // Default: new goal becomes primary
    var setAsPrimary = true;

    if (!context.mounted) return;

    // Show the dialog and wait for user action
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

                    // Goal title input
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Goal name',
                        hintText: 'e.g. Emergency fund',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 16),

                    // Target amount input
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Target amount',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // Checkbox to make it primary
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

              // Cancel / Add buttons
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: () {
                    // Validate input before closing the dialog
                    final title = titleController.text.trim();
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', '.'),
                    );
                    if (title.isEmpty) return;
                    if (amount == null || amount <= 0) return;

                    // Close dialog with "true" meaning accepted
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

    // If user cancelled, stop
    if (result != true) return;

    // Read inputs again
    final title = titleController.text.trim();
    final amount = double.tryParse(
      amountController.text.trim().replaceAll(',', '.'),
    );

    // Final validation
    if (title.isEmpty || amount == null || amount <= 0) return;

    // Create a new Goal object
    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      targetAmount: amount,
      isPrimary: setAsPrimary,
      createdAt: DateTime.now(),
    );

    // Add goal to the store
    goalsStore.addGoal(goal);
  }

  // Dialog to add savings to an existing goal
  Future<void> _showAddSavingsDialog(
    BuildContext context,
    GoalsStore goalsStore,
    Goal goal,
    String currencySymbol,
  ) async {

    // Maximum allowed is whatever is left to reach target
    final maxAdd = goal.targetAmount - goal.savedAmount;

    // If already reached, show message and stop
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

    // Show dialog asking how much to add
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to "${goal.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Show current saved vs target
            Text(
              'Current: $currencySymbol${goal.savedAmount.toStringAsFixed(0)} / $currencySymbol${goal.targetAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 6),

            // Show max allowed to add
            Text(
              'Max you can add: $currencySymbol${maxAdd.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 16),

            // Amount input
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

          // Add button returns the entered amount
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

    // If user entered a valid amount
    if (result != null && result > 0 && context.mounted) {

      // Add amount to the goal (store might clamp it to maxAdd)
      final actualAdded = goalsStore.addToSavedAmount(goal.id, result);

      if (actualAdded > 0) {

        // Also record it as an EXPENSE transaction (Savings category)
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

        // Show a quick message at the bottom
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added $currencySymbol${actualAdded.toStringAsFixed(0)} to ${goal.title}',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Check if goal became completed after adding
        final updated = goalsStore.goals.where((g) => g.id == goal.id).firstOrNull;

        // If completed, show congratulations dialog
        if (updated != null && updated.isCompleted) {
          _showCongratsDialog(context, goal.title);
        }
      }
    }
  }

  // Shows a "goal completed" popup
  void _showCongratsDialog(BuildContext context, String goalTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        // Title row with celebration icon
        title: Row(
          children: [
            Icon(Icons.celebration_rounded, color: Colors.green.shade700, size: 32),
            const SizedBox(width: 12),
            const Expanded(child: Text('Congratulations!')),
          ],
        ),

        // Message
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

  // Confirm dialog before removing a goal
  Future<void> _confirmRemoveGoal(
    BuildContext context,
    GoalsStore goalsStore,
    Goal goal,
  ) async {

    // Ask user to confirm
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
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFB71C1C)),
            ),
          ),
        ],
      ),
    );

    // If confirmed, remove from store
    if (ok == true) goalsStore.removeGoal(goal.id);
  }
}

// Big icon at the top (savings jar hero)
class _SavingsJarHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),

      // Circle background with shadow
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

      // Icon inside
      child: Icon(
        Icons.savings_rounded,
        size: 72,
        color: Colors.green.shade700,
      ),
    );
  }
}

// The two quick action cards under the header
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

            // If primary goal exists show quick deposit, otherwise same as new goal
            label: onQuickDeposit != null ? 'Quick deposit' : 'New goal',
            onTap: onQuickDeposit ?? onAddGoal,
          ),
        ),
      ],
    );
  }
}

// A single small card button
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

          // Card border styling
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

// Card widget for a single goal
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

    // Calculate progress (0.0 to 1.0)
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    // True if completed
    final isComplete = goal.isCompleted;

    return Card(
      elevation: 0,

      // Completed goals have a light green background
      color: isComplete ? Colors.green.shade50 : null,

      // Border styling (thicker for primary/completed)
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

            // Completed message at top of card
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

            // Row with icon + title + menu
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

                // Title and "primary goal" label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,

                          // Strike through if complete
                          decoration: isComplete ? TextDecoration.lineThrough : null,
                          color: isComplete ? Colors.grey.shade700 : Colors.grey.shade800,
                        ),
                      ),

                      // Show "Primary goal" text if this goal is primary
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

                // If complete show check icon, otherwise show menu to remove
                if (isComplete)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 28)
                else
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),

                    // Only one option: remove
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

            // Amounts row + percent
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

                // Percent only if not complete
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

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            ),

            // Buttons (only if not complete)
            if (!isComplete) ...[
              const SizedBox(height: 14),
              Row(
                children: [

                  // Add savings button
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

                  // Primary button (only if not already primary)
                  if (!goal.isPrimary)
                    TextButton.icon(
                      onPressed: onSetPrimary,
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('Primary'),
                    ),

                  // Done button (marks completed)
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
