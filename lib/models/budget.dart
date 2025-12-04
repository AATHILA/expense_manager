class Budget {
  String id;
  String category;
  double limit;
  int month;
  int year;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.month,
    required this.year,
  });

  Budget copyWith({
    String? id,
    String? category,
    double? limit,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  // Convert Budget to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'budget_limit': limit,
      'month': month,
      'year': year,
    };
  }

  // Create Budget from Map
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      category: map['category'] as String,
      limit: map['budget_limit'] as double,
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }
}

