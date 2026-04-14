class BudgetAlertPreference {
  String category;
  int month;
  int year;
  bool skipAlerts;

  BudgetAlertPreference({
    required this.category,
    required this.month,
    required this.year,
    required this.skipAlerts,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'month': month,
      'year': year,
      'skip_alerts': skipAlerts ? 1 : 0,
    };
  }

  // Create from Map
  factory BudgetAlertPreference.fromMap(Map<String, dynamic> map) {
    return BudgetAlertPreference(
      category: map['category'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      skipAlerts: map['skip_alerts'] == 1,
    );
  }

  // Create unique key for this preference
  String get key => '${category}_${month}_$year';
}

