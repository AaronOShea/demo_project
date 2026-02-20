class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final bool isPrimary;
  final bool isCompleted;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0,
    this.isPrimary = false,
    this.isCompleted = false,
    required this.createdAt,
  });

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    bool? isPrimary,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      isPrimary: isPrimary ?? this.isPrimary,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
