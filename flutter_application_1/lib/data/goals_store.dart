import 'package:flutter/foundation.dart';
import '../models/goal_model.dart';

class GoalsStore extends ChangeNotifier {
  final List<Goal> _goals = [];

  List<Goal> get goals => List.unmodifiable(_goals);

  Goal? get primaryGoal =>
      _goals.where((g) => g.isPrimary).firstOrNull;

  int get goalsCompletedCount =>
      _goals.where((g) => g.isCompleted).length;

  void addGoal(Goal goal) {
    // If this is set as primary, clear primary from others.
    if (goal.isPrimary) {
      for (var i = 0; i < _goals.length; i++) {
        if (_goals[i].isPrimary) {
          _goals[i] = _goals[i].copyWith(isPrimary: false);
        }
      }
    }
    _goals.add(goal);
    notifyListeners();
  }

  void setPrimary(String id) {
    for (var i = 0; i < _goals.length; i++) {
      _goals[i] = _goals[i].copyWith(isPrimary: _goals[i].id == id);
    }
    notifyListeners();
  }

  void markCompleted(String id) {
    for (var i = 0; i < _goals.length; i++) {
      if (_goals[i].id == id) {
        _goals[i] = _goals[i].copyWith(isCompleted: true);
        break;
      }
    }
    notifyListeners();
  }

  void removeGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  void updateSavedAmount(String id, double amount) {
    for (var i = 0; i < _goals.length; i++) {
      if (_goals[i].id == id) {
        _goals[i] = _goals[i].copyWith(savedAmount: amount);
        break;
      }
    }
    notifyListeners();
  }

  /// Add amount to a goal's saved total (capped so it never exceeds target).
  /// Returns the amount actually added. Auto-marks goal complete when target is reached.
  double addToSavedAmount(String id, double amount) {
    if (amount <= 0) return 0;
    for (var i = 0; i < _goals.length; i++) {
      if (_goals[i].id == id) {
        final g = _goals[i];
        final room = g.targetAmount - g.savedAmount;
        if (room <= 0) return 0;
        final toAdd = amount > room ? room : amount;
        final newSaved = g.savedAmount + toAdd;
        final isNowComplete = newSaved >= g.targetAmount;
        _goals[i] = g.copyWith(
          savedAmount: newSaved,
          isCompleted: isNowComplete || g.isCompleted,
        );
        notifyListeners();
        return toAdd;
      }
    }
    return 0;
  }
}
