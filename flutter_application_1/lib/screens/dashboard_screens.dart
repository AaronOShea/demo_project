import 'package:flutter/material.dart';
import '../app/transaction_provider.dart';
import '../app/settings_provider.dart';
import '../data/transaction_store.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';
import 'category_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _categoryIcons = {
    'Savings': Icons.savings_rounded,
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.favorite_rounded,
    'Other': Icons.category_rounded,
  };

  static IconData _iconForCategory(String category, Map<String, IconData> icons) {
    return icons[category] ?? Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final store = TransactionProvider.of(context);
    final settingsStore = SettingsProvider.of(context);
    final currencySymbol = settingsStore.currencySymbol;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      appBar: AppBar(
        title: const Text('Budget'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Set monthly budget',
            onPressed: () => _showSetBudgetDialog(context, store, currencySymbol),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(
                initialType: TransactionType.expense,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([store, settingsStore]),
        builder: (context, _) {
          final spent = store.spentThisMonth;
          final budget = store.monthlyBudget;
          final hasBudget = store.hasBudgetSet;
          final effectiveIncome = settingsStore.effectiveMonthlyIncome;
          final total = hasBudget && budget > 0 ? budget : effectiveIncome;
          final left = total - spent;
          final expenses = store.expensesThisMonth;
          final byCategory = store.spentByCategoryThisMonth;
          final categories = [...expenseCategories, ...store.customCategories];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MonthHeader(),
                      const SizedBox(height: 20),
                      _BudgetDoughnut(
                        spent: spent,
                        total: total,
                        currencySymbol: currencySymbol,
                      ),
                      const SizedBox(height: 20),
                      _SummaryRow(
                        spent: spent,
                        left: left,
                        currencySymbol: currencySymbol,
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle('Budget by category'),
                      const SizedBox(height: 12),
                      _BudgetCategoriesList(
                        categories: categories,
                        byCategory: byCategory,
                        store: store,
                        categoryIcons: _categoryIcons,
                        currencySymbol: currencySymbol,
                        onAddCategory: () => _showAddCategoryDialog(context, store),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle('Recent expenses'),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              if (expenses.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Center(
                      child: Text(
                        'No expenses this month yet.\nTap "Add Expense" to log one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final t = expenses[index];
                        return _ExpenseListTile(
                          transaction: t,
                          categoryIcons: _categoryIcons,
                          currencySymbol: currencySymbol,
                        );
                      },
                      childCount: expenses.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

void _showSetBudgetDialog(
  BuildContext context,
  TransactionStore store,
  String currencySymbol,
) {
  final controller = TextEditingController(
    text: store.monthlyBudget > 0 ? store.monthlyBudget.toStringAsFixed(0) : '',
  );
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Monthly budget'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Amount',
          prefixText: '$currencySymbol ',
        ),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
          onPressed: () {
            final v = double.tryParse(controller.text.trim().replaceAll(',', '.'));
            if (v != null && v >= 0) {
              store.setMonthlyBudget(v);
              if (context.mounted) Navigator.pop(ctx);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showAddCategoryDialog(BuildContext context, TransactionStore store) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add category'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Category name',
          hintText: 'e.g. Subscriptions',
        ),
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              store.addCustomCategory(name);
              if (context.mounted) Navigator.pop(ctx);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

class _MonthHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final now = DateTime.now();
    final monthName = months[now.month - 1];
    return Text(
      monthName,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }
}

class _BudgetDoughnut extends StatelessWidget {
  final double spent;
  final double total;
  final String currencySymbol;

  const _BudgetDoughnut({
    required this.spent,
    required this.total,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total > 0 ? total : 1.0;
    final spentPct = (spent / safeTotal).clamp(0.0, 1.0);
    final remainingPct = 1.0 - spentPct;
    final left = total - spent;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _DoughnutPainter(
                  spentFraction: spentPct,
                  spentColor: const Color(0xFF1B5E20),
                  remainingColor: left >= 0 ? const Color(0xFF1565C0) : const Color(0xFFB71C1C),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: const Color(0xFF1B5E20)),
                const SizedBox(width: 6),
                Text('Spent', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(width: 20),
                _LegendDot(color: left >= 0 ? const Color(0xFF1565C0) : const Color(0xFFB71C1C)),
                const SizedBox(width: 6),
                Text(left >= 0 ? 'Left' : 'Over', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  final double spentFraction;
  final Color spentColor;
  final Color remainingColor;

  _DoughnutPainter({
    required this.spentFraction,
    required this.spentColor,
    required this.remainingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;
    const strokeWidth = 24.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = -3.14159265359 / 2; // top
    final remainingFraction = 1.0 - spentFraction;
    if (spentFraction > 0) {
      final spentPaint = Paint()
        ..color = spentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, spentFraction * 2 * 3.14159265359, false, spentPaint);
    }
    if (remainingFraction > 0) {
      final remainingPaint = Paint()
        ..color = remainingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        startAngle + spentFraction * 2 * 3.14159265359,
        remainingFraction * 2 * 3.14159265359,
        false,
        remainingPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DoughnutPainter old) =>
      old.spentFraction != spentFraction || old.spentColor != spentColor || old.remainingColor != remainingColor;
}

class _SummaryRow extends StatelessWidget {
  final double spent;
  final double left;
  final String currencySymbol;

  const _SummaryRow({
    required this.spent,
    required this.left,
    required this.currencySymbol,
  });

  String _fmt(double v) {
    final abs = v.abs();
    if (abs >= 1000) {
      return abs.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return abs.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final leftColor = left >= 0 ? const Color(0xFF1565C0) : const Color(0xFFB71C1C);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spent', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                Text(
                  '$currencySymbol${_fmt(spent)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: leftColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(left >= 0 ? 'Left' : 'Over', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                Text(
                  '${left >= 0 ? '' : '-'}$currencySymbol${_fmt(left.abs())}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: leftColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }
}

class _BudgetCategoriesList extends StatelessWidget {
  final List<String> categories;
  final Map<String, double> byCategory;
  final TransactionStore store;
  final Map<String, IconData> categoryIcons;
  final String currencySymbol;
  final VoidCallback onAddCategory;

  const _BudgetCategoriesList({
    required this.categories,
    required this.byCategory,
    required this.store,
    required this.categoryIcons,
    required this.currencySymbol,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...categories.map((category) {
          final spent = byCategory[category] ?? 0.0;
          final limit = store.getCategoryLimit(category);
          return _BudgetCategoryCard(
            categoryName: category,
            spent: spent,
            limit: limit,
            icon: DashboardScreen._iconForCategory(category, categoryIcons),
            currencySymbol: currencySymbol,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(categoryName: category),
                ),
              );
            },
            onSetLimit: () => _showSetLimitDialog(context, store, category),
          );
        }),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onAddCategory,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_rounded, color: Colors.grey.shade600, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSetLimitDialog(
    BuildContext context,
    TransactionStore store,
    String category,
  ) {
    final controller = TextEditingController(
      text: store.getCategoryLimit(category)?.toStringAsFixed(0) ?? '',
    );
    final symbol = currencySymbol;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set limit for $category'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Monthly limit',
            prefixText: '$symbol ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0) {
                store.setCategoryLimit(category, amount);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  final String categoryName;
  final double spent;
  final double? limit;
  final IconData icon;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback onSetLimit;

  const _BudgetCategoryCard({
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.icon,
    required this.currencySymbol,
    required this.onTap,
    required this.onSetLimit,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = limit != null && limit! > 0;
    final ratio = hasLimit ? (spent / limit!).clamp(0.0, 1.5) : 0.0;
    Color barColor;
    if (!hasLimit) {
      barColor = Colors.grey.shade300;
    } else if (ratio <= 0.75) {
      barColor = const Color(0xFF2E7D32);
    } else if (ratio <= 1.0) {
      barColor = const Color(0xFFF9A825);
    } else {
      barColor = const Color(0xFFB71C1C);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.green.shade700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasLimit)
                    TextButton(
                      onPressed: () => onSetLimit(),
                      child: const Text('Edit limit'),
                    )
                  else
                    TextButton(
                      onPressed: () => onSetLimit(),
                      child: const Text('Set limit'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasLimit
                    ? '$currencySymbol${spent.toStringAsFixed(0)} / $currencySymbol${limit!.toStringAsFixed(0)}'
                    : 'Spent: $currencySymbol${spent.toStringAsFixed(0)} (no limit set)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: hasLimit ? ratio.clamp(0.0, 1.0) : 0.0,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              if (hasLimit && ratio > 1.0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Over by $currencySymbol${(spent - limit!).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  final Transaction transaction;
  final Map<String, IconData> categoryIcons;
  final String currencySymbol;

  const _ExpenseListTile({
    required this.transaction,
    required this.categoryIcons,
    required this.currencySymbol,
  });

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final icon = categoryIcons[transaction.category] ?? Icons.category_rounded;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 22),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _formatDate(transaction.date),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Text(
          '$currencySymbol${transaction.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1B5E20),
          ),
        ),
      ),
    );
  }
}
