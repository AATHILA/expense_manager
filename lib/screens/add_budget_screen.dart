import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../blocs/budget/budget_bloc.dart';
import '../blocs/budget/budget_event.dart';
import '../services/currency_services.dart';
import '../services/storage_services.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  List<ExpenseCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.budget != null) {
      _limitController.text = widget.budget!.limit.toString();
      _selectedCategory = widget.budget!.category;
      _selectedMonth = DateTime(widget.budget!.year, widget.budget!.month);
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await StorageService.getCategoriesByType(true); // Only expense categories for budgets
    setState(() {
      _categories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'Add Budget' : 'Edit Budget'),
        actions: widget.budget != null
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteBudget,
          ),
        ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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

            // Limit
            FutureBuilder<String>(
              future: CurrencyService.getCurrencySymbol(),
              builder: (context, snapshot) {
                final currencySymbol = snapshot.data ?? '₹';
                return TextFormField(
                  controller: _limitController,
                  decoration: InputDecoration(
                    labelText: 'Budget Limit',
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
                      return 'Please enter a budget limit';
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

            // Month/Year Selector
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              leading: const Icon(Icons.calendar_month),
              title: const Text('Month'),
              subtitle: Text(
                '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
              ),
              onTap: _selectMonth,
            ),
            const SizedBox(height: 24),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _saveBudget,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(widget.budget == null ? 'Add Budget' : 'Update Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check for duplicate budget (same category, month, and year)
      final isDuplicate = await _checkDuplicateBudget(
        _selectedCategory!,
        _selectedMonth.month,
        _selectedMonth.year,
      );

      if (isDuplicate) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A budget for "$_selectedCategory" in ${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year} already exists',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final budget = Budget(
        id: widget.budget?.id ?? const Uuid().v4(),
        category: _selectedCategory!,
        limit: double.parse(_limitController.text),
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );

      if (!mounted) return;

      if (widget.budget == null) {
        context.read<BudgetBloc>().add(AddBudget(budget));
      } else {
        context.read<BudgetBloc>().add(UpdateBudget(budget));
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.budget == null
                ? 'Budget added successfully'
                : 'Budget updated successfully',
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

  Future<bool> _checkDuplicateBudget(String category, int month, int year) async {
    final budgets = await StorageService.getAllBudgetsAsync();

    // If editing, exclude the current budget from duplicate check
    final currentBudgetId = widget.budget?.id;

    return budgets.any((budget) =>
    budget.category == category &&
        budget.month == month &&
        budget.year == year &&
        budget.id != currentBudgetId
    );
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
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

    if (confirmed == true && widget.budget != null && mounted) {
      context.read<BudgetBloc>().add(DeleteBudget(widget.budget!.id));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget deleted successfully')),
      );
    }
  }
}

