import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/currency_services.dart';
import '../services/storage_services.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: CurrencyService.getCurrencySymbol(),
      builder: (context, snapshot) {
        final currencySymbol = snapshot.data ?? '₹';
        final currencyFormatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
        final dateFormatter = DateFormat('MMM dd, yyyy');
        final isExpense = transaction.type == TransactionType.expense;

        return _buildListItem(context, currencyFormatter, dateFormatter, isExpense);
      },
    );
  }

  Widget _buildListItem(BuildContext context, NumberFormat currencyFormatter, DateFormat dateFormatter, bool isExpense) {

    return FutureBuilder<ExpenseCategory?>(
      future: StorageService.getCategoryByName(
        transaction.category,
        transaction.type == TransactionType.expense,
      ),
      builder: (context, snapshot) {
        final category = snapshot.data;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: onTap,
            leading: CircleAvatar(
              backgroundColor: category?.color.withValues(alpha: 0.2) ?? Colors.grey.withValues(alpha: 0.2),
              child: Icon(
                category?.icon ?? Icons.help_outline,
                color: category?.color ?? Colors.grey,
              ),
            ),
            title: Text(
              transaction.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.category),
                Text(
                  dateFormatter.format(transaction.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Text(
              '${isExpense ? '-' : '+'}${currencyFormatter.format(transaction.amount)}',
              style: TextStyle(
                color: isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}

