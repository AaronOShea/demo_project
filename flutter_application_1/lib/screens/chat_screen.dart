import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../app/transaction_provider.dart';
import '../app/settings_provider.dart';
import '../data/transaction_store.dart';
import '../models/transaction_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          "Hi, I’m your finance coach. Ask me anything about your spending, budget, or goals and I’ll give you practical tips.",
      fromCoach: true,
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Backend URL: Android emulator uses 10.0.2.2 to reach host machine;
  static String get _backendUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// Build user context from TransactionStore and SettingsStore for personalised AI answers.
  static Map<String, dynamic>? _buildUserContext(BuildContext context, TransactionStore store) {
    final settingsStore = SettingsProvider.of(context);
    
    // Use effective monthly income from settings as the primary income value
    // This is the income the user has configured, even if they haven't added income transactions
    final effectiveIncome = settingsStore.effectiveMonthlyIncome;
    final transactionIncome = store.incomeThisMonth;
    
    // Use transaction income if available, otherwise use the configured effective income
    final income = transactionIncome > 0 ? transactionIncome : effectiveIncome;
    
    final spent = store.spentThisMonth;
    final budget = store.monthlyBudget;
    
    // Calculate remaining: use budget if set, otherwise use effective income - spent
    final remaining = budget > 0 ? (budget - spent) : (effectiveIncome - spent);
    
    // Recalculate spent percentage using the effective income
    final spentPct = effectiveIncome > 0 ? (spent / effectiveIncome * 100).clamp(0.0, 200.0) : 0.0;
    
    final byCategory = store.spentByCategoryThisMonth;
    final hasBudget = store.hasBudgetSet;

    final categoryLimits = <String, double>{};
    for (final cat in expenseCategories) {
      final limit = store.getCategoryLimit(cat);
      if (limit != null) categoryLimits[cat] = limit;
    }

    final recent = store.expensesThisMonth.take(10).map((t) => {
      'category': t.category,
      'amount': t.amount,
      'date': t.date.toIso8601String().substring(0, 10),
      if (t.note != null && t.note!.isNotEmpty) 'note': t.note,
    }).toList();

    return {
      'income_this_month': income,
      'expected_monthly_income': effectiveIncome,  // The configured monthly income from settings
      'spent_this_month': spent,
      'monthly_budget': budget,
      'remaining_this_month': remaining,
      'has_budget_set': hasBudget,
      'spent_percentage_of_income': spentPct,
      'spent_by_category': byCategory,
      'category_limits': categoryLimits,
      'recent_expenses': recent,
    };
  }

  Future<String> _fetchAIResponse(String message, Map<String, dynamic>? userContext) async {
    try {
      final body = <String, dynamic>{'message': message};
      if (userContext != null && userContext.isNotEmpty) {
        body['user_context'] = userContext;
      }
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ai-chat/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'Sorry, I could not generate a response.';
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error'] ?? 'Unknown error occurred';
          return 'Error: $errorMessage';
        } catch (_) {
          return 'Error: ${response.statusCode}. Please try again.';
        }
      }
    } catch (e) {
      return 'Failed to connect to the AI service. Please check your connection and ensure the backend is running.';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7F5),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF1B5E20),
                  ],
                ),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Coach',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  'Friendly guidance for your money',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _SuggestionChips(
                onTap: _handleSuggestionTapped,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _messages.length) {
                      final message = _messages[index];
                      return _ChatBubble(message: message);
                    } else {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSend(),
                          decoration: const InputDecoration(
                            hintText: 'Ask a question about your money…',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _handleSend,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSuggestionTapped(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  Future<void> _handleSend() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: raw,
          fromCoach: false,
        ),
      );
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    final store = TransactionProvider.of(context);
    final userContext = _buildUserContext(context, store);
    final reply = await _fetchAIResponse(raw, userContext);

    setState(() {
      _messages.add(
        _ChatMessage(
          text: reply,
          fromCoach: true,
        ),
      );
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

}

class _ChatMessage {
  final String text;
  final bool fromCoach;

  const _ChatMessage({
    required this.text,
    required this.fromCoach,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isCoach = message.fromCoach;
    final alignment =
        isCoach ? Alignment.centerLeft : Alignment.centerRight;
    final bubbleColor = isCoach
        ? const Color(0xFFE8F5E9)
        : const Color(0xFF2E7D32);
    final textColor = isCoach ? const Color(0xFF1B5E20) : Colors.white;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isCoach ? 4 : 18),
                bottomRight: Radius.circular(isCoach ? 18 : 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final void Function(String text) onTap;

  const _SuggestionChips({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'How can I cut my food spending?',
      'Help me create a simple budget',
      'What’s a good savings goal?',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final suggestion in suggestions) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                label: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => onTap(suggestion),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
