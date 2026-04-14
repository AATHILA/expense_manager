import 'package:expense_manager_project/screens/budget_screen.dart';
import 'package:expense_manager_project/screens/currency_setup_screen.dart';
import 'package:expense_manager_project/screens/dashboard_screen.dart';
import 'package:expense_manager_project/screens/notification_setup_screen.dart';
import 'package:expense_manager_project/screens/transaction_screen.dart';
import 'package:expense_manager_project/services/storage_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/transaction/transaction_bloc.dart';
import 'blocs/transaction/transaction_event.dart';

late double width;
late double height;
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return BlocProvider(
      create: (context) => TransactionBloc()..add(const LoadTransactions()),
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: DashboardScreen(),

        routes: {
          '/transactions': (context) => const TransactionsScreen(),
          // '/budgets': (context) => const BudgetsScreen(),
          //'/settings': (context) => const SettingsScreen(),
          //   '/categories': (context) => const CategoriesScreen(),
          //   '/currency-setup': (context) => const CurrencySetupScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
        ],
      ),
    );
  }
}

// App initializer to check if currency is set and show notification setup
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  void _triggerRebuild() {
    setState(() {
      // Trigger rebuild - just needs to call setState
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: StorageService.isCurrencySet(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        final isCurrencySet = snapshot.data ?? false;

        if (!isCurrencySet) {
          return const CurrencySetupScreen();
        }

        return FutureBuilder<String?>(
          future: StorageService.getSettingValue('notification_setup_done'),
          builder: (context, notificationSnapshot) {
            if (notificationSnapshot.connectionState ==
                ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            final notificationSetupDone =
                notificationSnapshot.data == 'true';

            if (!notificationSetupDone) {
              return NotificationSetupScreen(
                onComplete: () async {
                  await StorageService.setSettingValue(
                    'notification_setup_done',
                    'true',
                  );
                  if (mounted) {
                    _triggerRebuild();
                  }
                },
              );
            }

            return const MainScreen();
          },
        );
      },
    );
  }
}
