class BudgetModel {
  final int? id;
  final int categoryId;
  final double amount;
  final String month; // YYYY-MM

  const BudgetModel({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'amount': amount,
        'month': month,
      };

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        month: map['month'] as String,
      );
}
