class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'symbol': symbol,
      'name': name,
    };
  }

  // Create from Map
  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      code: map['code'] as String,
      symbol: map['symbol'] as String,
      name: map['name'] as String,
    );
  }
}

// Popular currencies list
class Currencies {
  static const List<Currency> popular = [
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro'),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
    Currency(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc'),
    Currency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
    Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
    Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
    Currency(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
    Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    Currency(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
    Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    Currency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
    Currency(code: 'MXN', symbol: 'Mex\$', name: 'Mexican Peso'),
    Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    Currency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    Currency(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
    Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
    Currency(code: 'VND', symbol: '₫', name: 'Vietnamese Dong'),
    Currency(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
    Currency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    Currency(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee'),
    Currency(code: 'NPR', symbol: 'रू', name: 'Nepalese Rupee'),
    Currency(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound'),
    Currency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
    Currency(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
  ];

  static Currency getByCode(String code) {
    return popular.firstWhere(
          (currency) => currency.code == code,
      orElse: () => popular[3], // Default to INR
    );
  }
}

