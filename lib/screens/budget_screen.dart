import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/budget/budget_bloc.dart';
import '../blocs/budget/budget_state.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/transaction/transaction_state.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/currency_services.dart';
import '../services/storage_service.dart';

import '../utils/page_route_builder.dart';
import 'add_budget_screen.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Budgets'),
            Text(
              DateFormat('MMMM yyyy').format(now),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, budgetState) {
          if (budgetState is BudgetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (budgetState is BudgetError) {
            return Center(child: Text('Error: ${budgetState.message}'));
          }

          if (budgetState is! BudgetLoaded) {
            return const Center(child: Text('No budgets yet'));
          }

          return BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, transactionState) {
              if (transactionState is! TransactionLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final budgets = budgetState.budgets
                  .where((b) => b.month == now.month && b.year == now.year)
                  .toList();

              if (budgets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No budgets set',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to set a budget',
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
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  final spent = transactionState.getCategoryExpenses(
                    budget.category,
                    now.month,
                    now.year,
                  );
                  final percentage = (spent / budget.limit) * 100;
                  final isOverBudget = spent > budget.limit;
                  final isNearBudget = percentage >= 80 && percentage < 100;

                  return _buildBudgetCard(
                    context,
                    budget,
                    spent,
                    percentage,
                    isOverBudget,
                    isNearBudget,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          navigateWithLoading(
            context,
            const AddBudgetScreen(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBudgetCard(
      BuildContext context,
      Budget budget,
      double spent,
      double percentage,
      bool isOverBudget,
      bool isNearBudget,
      ) {
    return FutureBuilder<String>(
      future: CurrencyService.getCurrencySymbol(),
      builder: (context, snapshot) {
        final currencySymbol = snapshot.data ?? '₹';
        final currencyFormatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);

        Color statusColor;
        if (isOverBudget) {
          statusColor = Colors.red;
        } else if (isNearBudget) {
          statusColor = Colors.orange;
        } else {
          statusColor = Colors.green;
        }

        return _buildBudgetCardContent(context, budget, spent, percentage, statusColor, currencyFormatter, isOverBudget, isNearBudget);
      },
    );
  }

  Widget _buildBudgetCardContent(
      BuildContext context,
      Budget budget,
      double spent,
      double percentage,
      Color statusColor,
      NumberFormat currencyFormatter,
      bool isOverBudget,
      bool isNearBudget,
      ) {

    return FutureBuilder<ExpenseCategory?>(
      future: StorageService.getCategoryByName(budget.category, true),
      builder: (context, snapshot) {
        final category = snapshot.data;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              navigateWithLoading(
                context,
                AddBudgetScreen(budget: budget),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: category?.color.withValues(alpha: 0.2),
                        child: Icon(
                          category?.icon ?? Icons.help_outline,
                          color: category?.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.category,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${currencyFormatter.format(spent)} of ${currencyFormatter.format(budget.limit)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (isOverBudget)
                            Text(
                              'Over budget!',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                              ),
                            )
                          else if (isNearBudget)
                            Text(
                              'Near limit',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage > 100 ? 1.0 : percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

