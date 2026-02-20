import 'package:flutter/material.dart';
import '../data/goals_store.dart';

class GoalsProvider extends InheritedNotifier<GoalsStore> {
  const GoalsProvider({
    super.key,
    required GoalsStore store,
    required super.child,
  }) : super(notifier: store);

  static GoalsStore of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<GoalsProvider>();
    assert(provider != null, 'No GoalsProvider found in context');
    return provider!.notifier!;
  }
}
