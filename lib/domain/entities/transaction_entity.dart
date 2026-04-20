enum TransactionType { income, expense }

class TransactionEntity {
  final String? id;
  final String userId;
  final String categoryId;
  final double amount;
  final String note;
  final DateTime date;
  final TransactionType type;

  TransactionEntity({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.note,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'type': type.name,
    };
  }

  factory TransactionEntity.fromMap(Map<String, dynamic> map) {
    return TransactionEntity(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      type: TransactionType.values.byName(map['type'] ?? 'expense'),
    );
  }
}
