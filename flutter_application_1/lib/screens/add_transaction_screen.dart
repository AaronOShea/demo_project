import 'package:flutter/material.dart';
import '../app/transaction_provider.dart';
import '../app/settings_provider.dart';
import '../models/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.initialType});

  final TransactionType? initialType;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late TransactionType _type;
  String _category = expenseCategories.first;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? TransactionType.expense;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount (e.g. 25 or 25.50)')),
      );
      return;
    }
    final store = TransactionProvider.of(context);
    final note = _noteController.text.trim();
    final t = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: _type,
      category: _type == TransactionType.expense ? _category : 'Income',
      date: DateTime.now(),
      note: note.isEmpty ? null : note,
    );
    store.addTransaction(t);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${SettingsProvider.of(context).currencySymbol} ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransactionType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: TransactionType.income,
                  child: Text('Income'),
                ),
                DropdownMenuItem(
                  value: TransactionType.expense,
                  child: Text('Expense'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            if (_type == TransactionType.expense) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final store = TransactionProvider.of(context);
                  final categories = [...expenseCategories, ...store.customCategories];
                  final value = categories.contains(_category) ? _category : categories.first;
                  if (value != _category) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _category = value);
                    });
                  }
                  return DropdownButtonFormField<String>(
                    value: value,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Lunch with friends',
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
