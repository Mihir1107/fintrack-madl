class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income' | 'expense'
  final int? categoryId;
  final DateTime date;
  final String? notes;

  const TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'] as int?,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        categoryId: map['category_id'] as int?,
        date: DateTime.parse(map['date'] as String),
        notes: map['notes'] as String?,
      );

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    int? categoryId,
    DateTime? date,
    String? notes,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        date: date ?? this.date,
        notes: notes ?? this.notes,
      );
}
