
import 'package:expense_manager_project/services/storage_services.dart';


class CurrencyService {
  static String? _cachedSymbol;

  // Get the current currency symbol
  static Future<String> getCurrencySymbol() async {
    if (_cachedSymbol != null) {
      return _cachedSymbol!;
    }

    final symbol = await StorageService.getCurrencySymbol();
    _cachedSymbol = symbol ?? '₹'; // Default to INR if not set
    return _cachedSymbol!;
  }

  // Set currency and update cache
  static Future<void> setCurrency(String code, String symbol) async {
    await StorageService.setCurrency(code, symbol);
    _cachedSymbol = symbol;
  }

  // Clear cache (useful when currency is changed)
  static void clearCache() {
    _cachedSymbol = null;
  }

   // Initialize cache on app start
  static Future<void> init() async {
    _cachedSymbol = await StorageService.getCurrencySymbol();
  }
}

