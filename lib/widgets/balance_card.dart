
import 'package:flutter/material.dart';

import 'metric_container.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard(BuildContext context, {super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  double currentBalance = 0.00;
  double totalExpenses = 0.00;
  double totalIncome = 0.00;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.primary, // Use primary color for the dark card
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Balance',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              '₹${currentBalance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricContainer(
                    context,
                    label: 'Income',
                    amount: totalIncome,
                    icon: Icons.arrow_downward,
                    color: Colors.greenAccent, // Green for Income
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricContainer(
                    context,
                    label: 'Expenses',
                    amount: totalExpenses,
                    icon: Icons.arrow_upward,
                    color: Colors.redAccent, // Red for Expenses
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

