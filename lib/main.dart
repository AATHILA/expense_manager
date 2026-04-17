import 'package:expense_manager_project/screens/budget_screen.dart';
import 'package:expense_manager_project/screens/transaction_screen.dart';
import 'package:expense_manager_project/services/currency_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'blocs/transaction/transaction_bloc.dart';
import 'blocs/transaction/transaction_event.dart';
import 'blocs/budget/budget_bloc.dart';
import 'blocs/budget/budget_event.dart';
import 'blocs/category/category_bloc.dart';
import 'blocs/category/category_event.dart';
import 'blocs/theme/theme_bloc.dart';
import 'blocs/theme/theme_state.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/currency_setup_screen.dart';
import 'screens/notification_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await CurrencyService.init();
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TransactionBloc()..add(const LoadTransactions()),
        ),
        BlocProvider(
          create: (_) => BudgetBloc()..add(const LoadBudgets()),
        ),
        BlocProvider(
          create: (_) => CategoryBloc()..add(LoadCategories()),
        ),
        BlocProvider(
          create: (_) => ThemeBloc(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Expense Manager',
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeState.themeMode,
            debugShowCheckedModeBanner: false,
            home: const AppInitializer(),
            routes: {
              '/transactions': (context) => const TransactionsScreen(),
              '/budgets': (context) => const BudgetsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/categories': (context) => const CategoriesScreen(),
              '/currency-setup': (context) => const CurrencySetupScreen(),
            },
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
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
