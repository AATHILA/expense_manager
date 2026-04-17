import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/transaction/transaction_event.dart';
import '../blocs/transaction/transaction_state.dart';
import '../models/transaction.dart';
import '../widgets/transaction_list_item.dart';
import '../utils/page_route_builder.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    // Initialize with current month range
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0); // Last day of current month
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          // Month filter button
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filter by Month',
            onPressed: _selectMonth,
          ),
          // Type filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Income', child: Text('Income')),
              const PopupMenuItem(value: 'Expense', child: Text('Expense')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range filter chip
          if (_fromDate != null && _toDate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.date_range, size: 18),
                    label: Text(_getDateRangeText()),
                    onDeleted: _clearDateFilter,
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          // Transactions list
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TransactionError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                if (state is! TransactionLoaded) {
                  return const Center(child: Text('No transactions yet'));
                }

                List<Transaction> transactions = state.transactions;

                // Apply date range filter if selected
                if (_fromDate != null && _toDate != null) {
                  transactions = transactions.where((t) {
                    return t.date.isAfter(_fromDate!.subtract(const Duration(days: 1))) &&
                        t.date.isBefore(_toDate!.add(const Duration(days: 1)));
                  }).toList();
                }

                // Apply type filter
                switch (_filter) {
                  case 'Income':
                    transactions = transactions
                        .where((t) => t.type == TransactionType.income)
                        .toList();
                    break;
                  case 'Expense':
                    transactions = transactions
                        .where((t) => t.type == TransactionType.expense)
                        .toList();
                    break;
                  default:
                  // Keep all transactions (already filtered by month if applicable)
                    break;
                }

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a transaction',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Dismissible(
                      key: Key(transaction.id),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Transaction'),
                            content: const Text('Are you sure you want to delete this transaction?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        context.read<TransactionBloc>().add(DeleteTransaction(transaction.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Transaction deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                context.read<TransactionBloc>().add(AddTransaction(transaction));
                              },
                            ),
                          ),
                        );
                      },
                      child: TransactionListItem(
                        transaction: transaction,
                        onTap: () {
                          navigateWithLoading(
                            context,
                            AddTransactionScreen(
                              transaction: transaction,
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          navigateWithLoading(
            context,
            const AddTransactionScreen(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _selectMonth() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      helpText: 'Select Date Range',
      cancelText: 'Cancel',
      confirmText: 'Apply',
      saveText: 'Save',
      fieldStartHintText: 'From Date',
      fieldEndHintText: 'To Date',
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  String _getDateRangeText() {
    if (_fromDate == null || _toDate == null) return '';
    final dateFormat = DateFormat('MMM dd, yyyy');
    return '${dateFormat.format(_fromDate!)} - ${dateFormat.format(_toDate!)}';
  }
}

