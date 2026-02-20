import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../app/settings_provider.dart';
import '../app/goals_provider.dart';
import '../data/settings_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onNavigateToGoals});

  final VoidCallback? onNavigateToGoals;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  String? _displayName;
  int _savingsTargetPercent = 20;
  Uint8List? _profileImageBytes;

  static const double _incomeMin = 1000;
  static const double _incomeMax = 10000;
  static const double _incomeStep = 250;
  static const int _savingsMin = 5;
  static const int _savingsMax = 50;
  static const int _savingsStep = 5;

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;
    final bytes = await xFile.readAsBytes();
    if (mounted) setState(() => _profileImageBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final email = user?.email ?? 'Unknown user';
    final createdAt = user?.metadata.creationTime;
    final memberSince = _formatMemberSince(createdAt);
    final initials = _initialsFromEmail(email);
    final displayName = _displayName ?? _deriveDisplayNameFromEmail(email);
    final settingsStore = SettingsProvider.of(context);
    final goalsStore = GoalsProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _showEditDisplayNameDialog(context, displayName),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeaderCard(
                displayName: displayName,
                email: email,
                memberSince: memberSince,
                initials: initials,
                profileImageBytes: _profileImageBytes,
                onTapPhoto: _pickProfileImage,
              ),
              const SizedBox(height: 28),
              _SectionTitle('Goals'),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: goalsStore,
                builder: (context, _) {
                  final primary = goalsStore.primaryGoal;
                  final completed = goalsStore.goalsCompletedCount;
                  final hasGoals = goalsStore.goals.isNotEmpty;
                  if (!hasGoals) {
                    return _GoalsEmptyState(onAddGoal: widget.onNavigateToGoals);
                  }
                  return _GoalsCard(
                    primaryGoalTitle: primary?.title,
                    completedCount: completed,
                  );
                },
              ),
              const SizedBox(height: 28),
              _SectionTitle('Financial preferences'),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: settingsStore,
                builder: (context, _) => Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      children: [
                        _CurrencyRow(settingsStore: settingsStore),
                        const Divider(height: 24),
                        _IncomeSlider(
                          value: settingsStore.defaultMonthlyIncome,
                          currencySymbol: settingsStore.currencySymbol,
                          min: _incomeMin,
                          max: _incomeMax,
                          step: _incomeStep,
                          onChanged: (v) => settingsStore.setDefaultMonthlyIncome(v),
                        ),
                      const SizedBox(height: 8),
                        _SavingsSlider(
                          value: _savingsTargetPercent,
                          min: _savingsMin,
                          max: _savingsMax,
                          step: _savingsStep,
                          onChanged: (v) => setState(() => _savingsTargetPercent = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionTitle('Privacy'),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: Icon(Icons.lock_outline_rounded, color: Colors.green.shade700),
                  title: const Text(
                    'AI uses anonymised data only',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Aligned with GDPR and privacy-by-design.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionTitle('App settings'),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_rounded),
                      title: const Text('Notifications'),
                      value: _notifications,
                      onChanged: (v) => setState(() => _notifications = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => AuthService.instance.signOut(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB71C1C),
                            side: const BorderSide(color: Color(0xFFB71C1C)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Log out'),
                        ),
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

  String _formatMemberSince(DateTime? createdAt) {
    if (createdAt == null) return 'Member since —';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Member since ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  String _initialsFromEmail(String email) {
    final prefix = email.split('@').first;
    if (prefix.isEmpty) return '?';
    final parts = prefix.split('.');
    if (parts.length >= 2) {
      final a = parts[0].isNotEmpty ? parts[0][0] : '';
      final b = parts[1].isNotEmpty ? parts[1][0] : '';
      final combined = '$a$b'.trim();
      return combined.isEmpty ? prefix[0].toUpperCase() : combined.toUpperCase();
    }
    return prefix[0].toUpperCase();
  }

  String _deriveDisplayNameFromEmail(String email) {
    final prefix = email.split('@').first;
    if (prefix.isEmpty) return 'Your profile';
    final parts = prefix.split('.');
    if (parts.length >= 2) {
      return '${_capitalise(parts[0])} ${_capitalise(parts[1])}';
    }
    return _capitalise(prefix);
  }

  String _capitalise(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _showEditDisplayNameDialog(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit display name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) setState(() => _displayName = result);
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
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String memberSince;
  final String initials;
  final Uint8List? profileImageBytes;
  final VoidCallback onTapPhoto;

  const _ProfileHeaderCard({
    required this.displayName,
    required this.email,
    required this.memberSince,
    required this.initials,
    this.profileImageBytes,
    required this.onTapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: onTapPhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green.shade100,
                    child: profileImageBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              profileImageBytes!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            initials,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    memberSince,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsEmptyState extends StatelessWidget {
  final VoidCallback? onAddGoal;

  const _GoalsEmptyState({this.onAddGoal});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag_rounded,
                size: 48,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your goals will show up here',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Set a goal on the Goals tab and track your progress. Your primary goal and completed count will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddGoal,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add your first goal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  final String? primaryGoalTitle;
  final int completedCount;

  const _GoalsCard({
    required this.primaryGoalTitle,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.flag_rounded, color: Colors.green.shade700),
              title: const Text('Primary goal', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                primaryGoalTitle ?? 'None set',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              leading: Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade700),
              title: const Text('Goals completed', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '$completedCount',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  final SettingsStore settingsStore;

  const _CurrencyRow({required this.settingsStore});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.currency_exchange_rounded, color: Colors.green.shade700),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Currency', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        DropdownButton<String>(
          value: settingsStore.currency,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 'USD', child: Text('USD')),
            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
            DropdownMenuItem(value: 'GBP', child: Text('GBP')),
          ],
          onChanged: (v) {
            if (v != null) settingsStore.setCurrency(v);
          },
        ),
      ],
    );
  }
}

class _IncomeSlider extends StatelessWidget {
  final double value;
  final String currencySymbol;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const _IncomeSlider({
    required this.value,
    required this.currencySymbol,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.payments_rounded, size: 22, color: Colors.green.shade700),
                const SizedBox(width: 10),
                const Text('Default monthly income', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            Text(
              '$currencySymbol${value.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF2E7D32),
            thumbColor: const Color(0xFF2E7D32),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SavingsSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _SavingsSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.savings_rounded, size: 22, color: Colors.green.shade700),
                const SizedBox(width: 10),
                const Text('Savings target', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            Text(
              '$value%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF2E7D32),
            thumbColor: const Color(0xFF2E7D32),
          ),
          child: Slider(
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min) ~/ step,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
