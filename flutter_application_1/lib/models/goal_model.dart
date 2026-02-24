// A simple data model for a savings goal
class Goal {
  // Unique ID for the goal (used to find/update/delete it)
  final String id;

  // The name of the goal (e.g. "Emergency Fund")
  final String title;

  // The target amount you want to reach
  final double targetAmount;

  // How much has been saved so far
  final double savedAmount;

  // True if this is the main/featured goal
  final bool isPrimary;

  // True if the goal is finished/reached
  final bool isCompleted;

  // When the goal was created
  final DateTime createdAt;

  // Constructor for creating a Goal
  // Some fields have default values if not provided
  const Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0,        // default: nothing saved yet
    this.isPrimary = false,      // default: not primary
    this.isCompleted = false,    // default: not completed
    required this.createdAt,
  });

  // Creates a NEW Goal object using the current one,
  // but lets you replace any fields you want.
  // (Useful because this class uses final fields = immutable)
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
      id: id ?? this.id,                     // if new id not given, keep old
      title: title ?? this.title,            // if new title not given, keep old
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      isPrimary: isPrimary ?? this.isPrimary,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
