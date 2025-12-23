import 'package:equatable/equatable.dart';
import '../../models/transaction.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;

  const TransactionLoaded(this.transactions);

  @override
  List<Object> get props => [transactions];

  // Helper methods for calculations
  double getTotalIncome() {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses() {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getCurrentBalance() {
    return getTotalIncome() - getTotalExpenses();
  }

  Map<String, double> getExpensesByCategory() {
    final Map<String, double> categoryExpenses = {};

    for (var transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryExpenses[transaction.category] =
            (categoryExpenses[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categoryExpenses;
  }

  List<Transaction> getRecentTransactions({int limit = 5}) {
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  double getMonthlyExpenses(int month, int year) {
    return transactions
        .where((t) =>
    t.type == TransactionType.expense &&
        t.date.month == month &&
        t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getCategoryExpenses(String category, int month, int year) {
    return transactions
        .where((t) =>
    t.type == TransactionType.expense &&
        t.category == category &&
        t.date.month == month &&
        t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object> get props => [message];
}

