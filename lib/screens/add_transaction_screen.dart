import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/currency_services.dart';

import '../services/storage_services.dart';
import '../widgets/budget_breach_alert_dialog.dart';
//import '../widgets/budget_breach_alert_dialog.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<ExpenseCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes ?? '';
      _type = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await StorageService.getCategoriesByType(
      _type == TransactionType.expense,
    );
    setState(() {
      _categories = categories;
      // Reset selected category if it doesn't exist in new type
      if (_selectedCategory != null &&
          !categories.any((c) => c.name == _selectedCategory)) {
        _selectedCategory = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Add Transaction' : 'Edit Transaction'),
        actions: widget.transaction != null
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTransaction,
          ),
        ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (Set<TransactionType> newSelection) {
                    setState(() {
                      _type = newSelection.first;
                      _selectedCategory = null;
                    });
                    _loadCategories();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount
            FutureBuilder<String>(
              future: CurrencyService.getCurrencySymbol(),
              builder: (context, snapshot) {
                final currencySymbol = snapshot.data ?? '₹';
                return TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: const OutlineInputBorder(),
                    prefixIcon: Center(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: Text(
                        currencySymbol,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category.name,
                  child: Row(
                    children: [
                      Icon(category.icon, color: category.color, size: 20),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _saveTransaction,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(widget.transaction == null ? 'Add Transaction' : 'Update Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = Transaction(
        id: widget.transaction?.id ?? const Uuid().v4(),
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        date: _selectedDate,
        type: _type,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (!mounted) return;

      // Check for budget breach only for expense transactions
      if (_type == TransactionType.expense) {
        final shouldProceed = await _checkBudgetBreach(transaction);
        if (!shouldProceed) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;

      // ⭐️ REPLACED BLOC CALLS WITH PLACEHOLDER ACTIONS
      if (widget.transaction == null) {
        print('ACTION: Add new transaction: ${transaction.title} (${transaction.amount})');
        // In a non-Bloc app, you would call a service here to save to a database.
        // Example: await StorageService.saveTransaction(transaction);
      } else {
        print('ACTION: Update transaction: ${transaction.title} (${transaction.amount}) ID: ${transaction.id}');
        // Example: await StorageService.updateTransaction(transaction);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transaction == null
                ? 'Transaction added successfully (Non-Bloc)'
                : 'Transaction updated successfully (Non-Bloc)',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed == true && widget.transaction != null && mounted) {
      // ⭐️ REPLACED BLOC CALL WITH PLACEHOLDER ACTION
      print('ACTION: Delete transaction with ID: ${widget.transaction!.id}');
      // Example: await StorageService.deleteTransaction(widget.transaction!.id);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully (Non-Bloc)')),
      );
    }
  }

  Future<bool> _checkBudgetBreach(Transaction transaction) async {
    try {
      // Get all budgets
      final budgets = await StorageService.getAllBudgetsAsync();

      // Find budget for this category and month
      final budget = budgets.where((b) =>
      b.category == transaction.category &&
          b.month == transaction.date.month &&
          b.year == transaction.date.year
      ).firstOrNull;

      // If no budget set, allow transaction
      if (budget == null) return true;

      // Check if user has opted to skip alerts for this budget this month
      final skipAlerts = await StorageService.shouldSkipBudgetAlert(
        transaction.category,
        transaction.date.month,
        transaction.date.year,
      );

      if (skipAlerts) return true;

      // Get all transactions for this category and month
      final allTransactions = await StorageService.getAllTransactionsAsync();
      final categoryTransactions = allTransactions.where((t) =>
      t.category == transaction.category &&
          t.type == TransactionType.expense &&
          t.date.month == transaction.date.month &&
          t.date.year == transaction.date.year &&
          t.id != transaction.id // Exclude current transaction if editing
      ).toList();

      // Calculate current spent
      final currentSpent = categoryTransactions.fold<double>(
        0.0,
            (sum, t) => sum + t.amount,
      );

      // Check if adding this transaction will breach the budget
      final totalAfterTransaction = currentSpent + transaction.amount;

      if (totalAfterTransaction > budget.limit) {
        // Show budget breach alert
        if (!mounted) return false;

        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => BudgetBreachAlertDialog(
            category: transaction.category,
            budgetLimit: budget.limit,
            currentSpent: currentSpent,
            newAmount: transaction.amount,
            month: transaction.date.month,
            year: transaction.date.year,
            onContinue: () {},
            onContinueWithPreference: (skipFuture) async {
              if (skipFuture) {
                await StorageService.setBudgetAlertPreference(
                  transaction.category,
                  transaction.date.month,
                  transaction.date.year,
                  true,
                );
              }
            },
          ),
        );

        return result ?? false;
      }

      return true;
    } catch (e) {
      // If there's an error checking budget, allow the transaction
      return true;
    }
  }
}