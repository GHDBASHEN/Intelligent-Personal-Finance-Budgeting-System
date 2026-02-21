enum TransactionType { income, expense }

class TransactionEntity {
  final int? id;
  final int userId;
  final int categoryId;
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
      id: map['id'],
      userId: map['user_id'],
      categoryId: map['category_id'],
      amount: (map['amount'] as num).toDouble(),
      note: map['note'],
      date: DateTime.parse(map['date']),
      type: TransactionType.values.byName(map['type']),
    );
  }
}
