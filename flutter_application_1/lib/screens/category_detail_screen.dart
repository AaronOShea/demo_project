import 'package:flutter/material.dart';
import '../app/transaction_provider.dart';
import '../app/settings_provider.dart';
import '../data/transaction_store.dart';
import '../models/transaction_model.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key, required this.categoryName});

  final String categoryName;

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

  @override
  Widget build(BuildContext context) {
    final store = TransactionProvider.of(context);
    final currencySymbol = SettingsProvider.of(context).currencySymbol;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final expenses = store.expensesInCategoryThisMonth(categoryName);
        final spent = expenses.fold<double>(0, (s, t) => s + t.amount);
        final limit = store.getCategoryLimit(categoryName);
        final icon = _categoryIcons[categoryName] ?? Icons.category_rounded;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF8),
          appBar: AppBar(
            title: Text(categoryName),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Set limit',
                onPressed: () => _showSetLimitDialog(context, store, currencySymbol),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.green.shade700, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spent this month',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '$currencySymbol${spent.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            if (limit != null && limit > 0)
                              Text(
                                'Limit: $currencySymbol${limit.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Expenses in $categoryName',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
              ),
              const SizedBox(height: 8),
              if (expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No expenses in this category yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              else
                ...expenses.map((t) => _ExpenseTile(transaction: t, currencySymbol: currencySymbol)),
            ],
          ),
        );
      },
    );
  }

  void _showSetLimitDialog(BuildContext context, TransactionStore store, String currencySymbol) {
    final controller = TextEditingController(
      text: store.getCategoryLimit(categoryName)?.toStringAsFixed(0) ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set limit for $categoryName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Monthly limit',
            prefixText: '$currencySymbol ',
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
                store.setCategoryLimit(categoryName, amount);
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

class _ExpenseTile extends StatelessWidget {
  final Transaction transaction;
  final String currencySymbol;

  const _ExpenseTile({required this.transaction, required this.currencySymbol});

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          transaction.note?.isNotEmpty == true
              ? transaction.note!
              : _formatDate(transaction.date),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: transaction.note?.isNotEmpty == true
            ? Text(
                _formatDate(transaction.date),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
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
