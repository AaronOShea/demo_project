import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class TransactionStore extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  final Map<String, double> _categoryLimits = {};
  final List<String> _customCategories = [];

  List<String> get customCategories => List.unmodifiable(_customCategories);

  void addCustomCategory(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    if (_customCategories.contains(n)) return;
    if (expenseCategories.contains(n)) return;
    _customCategories.add(n);
    notifyListeners();
  }

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  void addTransaction(Transaction t) {
    _transactions.add(t);
    notifyListeners();
  }

  /// Per-category monthly spending limit (e.g. Food: 150).
  double? getCategoryLimit(String category) =>
      _categoryLimits[category]?.clamp(0.0, double.infinity);

  void setCategoryLimit(String category, double limit) {
    if (limit <= 0) {
      _categoryLimits.remove(category);
    } else {
      _categoryLimits[category] = limit;
    }
    notifyListeners();
  }

  /// Expense transactions this month in a given category, newest first.
  List<Transaction> expensesInCategoryThisMonth(String category) {
    final list = _transactions
        .where((t) =>
            t.isExpense &&
            t.category == category &&
            _isThisMonth(t.date))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static bool _isThisMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  double get incomeThisMonth {
    return _transactions
        .where((t) => t.isIncome && _isThisMonth(t.date))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get spentThisMonth {
    return _transactions
        .where((t) => t.isExpense && _isThisMonth(t.date))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get netIncomeThisMonth => incomeThisMonth - spentThisMonth;

  /// Monthly spending budget. When set, "remaining" = budget - spent.
  double monthlyBudget = 0;

  void setMonthlyBudget(double value) {
    if (value == monthlyBudget) return;
    monthlyBudget = value;
    notifyListeners();
  }

  /// Money remaining for the month: budget - spent if budget is set, else income - spent.
  double get remainingThisMonth {
    if (monthlyBudget > 0) return monthlyBudget - spentThisMonth;
    return incomeThisMonth - spentThisMonth;
  }

  /// Whether user has set an explicit monthly budget.
  bool get hasBudgetSet => monthlyBudget > 0;

  /// Percentage of income spent this month (0-100). If no income, returns 0.
  double get spentPercentageOfIncome {
    if (incomeThisMonth <= 0) return 0;
    return (spentThisMonth / incomeThisMonth * 100).clamp(0.0, 200.0);
  }

  /// Category name -> total amount spent this month.
  Map<String, double> get spentByCategoryThisMonth {
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.isExpense && _isThisMonth(t.date)) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Expense transactions this month, newest first (for expenditure list).
  List<Transaction> get expensesThisMonth {
    final list = _transactions
        .where((t) => t.isExpense && _isThisMonth(t.date))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
