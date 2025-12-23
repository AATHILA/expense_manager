import 'package:expense_manager_project/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/transaction/transaction_bloc.dart';
import 'blocs/transaction/transaction_event.dart';

late double width;
late double height;
void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
   MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    width=MediaQuery.of(context).size.width;
    height=MediaQuery.of(context).size.height;
    return BlocProvider(
  create: (context) => TransactionBloc()..add(const LoadTransactions()),
  child: MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: DashboardScreen(),
    ),
);
  }
}

