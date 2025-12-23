import 'package:expense_manager_project/blocs/transaction/transaction_bloc.dart';
import 'package:expense_manager_project/blocs/transaction/transaction_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/transaction/transaction_event.dart';
import '../models/transaction.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_list_item.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- Placeholder Data ---

  double totalIncome = 0.00;
  double totalExpenses = 0.00;
  String currentMonth = 'December 2025';

  void navigateWithLoading(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (c) => screen));
  }

  List<Transaction> transactions = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Action for settings button
                print('Settings button pressed');
              },
            ),
          ],
        ),
        body: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TransactionError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is TransactionLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<TransactionBloc>().add(const LoadTransactions());
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Balance Card (Current Balance, Income, Expenses)
                      BalanceCard(context),
                      const SizedBox(height: 20),

                      // 2. Expense Chart Placeholder
                      _buildExpenseChartPlaceholder(context),
                      const SizedBox(height: 20),

                      // 3. Recent Transactions Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              // Action to navigate to 'See All' transactions
                              print('See All pressed');
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 4. Recent Transactions List/Placeholder
                      _buildRecentTransactionsPlaceholder(
                          context,  state.getRecentTransactions(limit: 5)),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: Text('No transactions yet'));
          },
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        elevation: 4,
      ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
  }

  Widget _buildExpenseChartPlaceholder(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        height: 150, // Fixed height for visual consistency
        child: Center(
          child: Text(
            'No expense data available for $currentMonth',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsPlaceholder(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    // This widget renders the 'No transactions yet' block shown in the image.

    if (transactions.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first transaction',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return TransactionListItem(
          transaction: transactions[index],
          onTap: () {
            navigateWithLoading(
              context,
              AddTransactionScreen(transaction: transactions[index]),
            );
          },
        );
      },
    );
  }
}
