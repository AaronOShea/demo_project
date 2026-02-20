import 'package:flutter/material.dart';
import '../data/settings_store.dart';

class SettingsProvider extends InheritedNotifier<SettingsStore> {
  const SettingsProvider({
    super.key,
    required SettingsStore store,
    required super.child,
  }) : super(notifier: store);

  static SettingsStore of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<SettingsProvider>();
    assert(provider != null, 'No SettingsProvider found in context');
    return provider!.notifier!;
  }
}
