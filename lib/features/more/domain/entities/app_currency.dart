enum AppCurrency {
  inr,
  usd,
  eur,
  gbp,
  jpy,
  cad,
  aud,
  sgd,
  aed,
  cny;

  static AppCurrency fromCode(String? code) => AppCurrency.values.firstWhere(
        (c) => c.code == code,
        orElse: () => AppCurrency.inr,
      );

  String get code => name.toUpperCase();

  String get symbol {
    switch (this) {
      case AppCurrency.inr:
        return '₹';
      case AppCurrency.usd:
        return '\$';
      case AppCurrency.eur:
        return '€';
      case AppCurrency.gbp:
        return '£';
      case AppCurrency.jpy:
        return '¥';
      case AppCurrency.cad:
        return 'C\$';
      case AppCurrency.aud:
        return 'A\$';
      case AppCurrency.sgd:
        return 'S\$';
      case AppCurrency.aed:
        return 'د.إ';
      case AppCurrency.cny:
        return '¥';
    }
  }

  String get currencyName {
    switch (this) {
      case AppCurrency.inr:
        return 'Indian Rupee';
      case AppCurrency.usd:
        return 'US Dollar';
      case AppCurrency.eur:
        return 'Euro';
      case AppCurrency.gbp:
        return 'British Pound';
      case AppCurrency.jpy:
        return 'Japanese Yen';
      case AppCurrency.cad:
        return 'Canadian Dollar';
      case AppCurrency.aud:
        return 'Australian Dollar';
      case AppCurrency.sgd:
        return 'Singapore Dollar';
      case AppCurrency.aed:
        return 'UAE Dirham';
      case AppCurrency.cny:
        return 'Chinese Yuan';
    }
  }

  String get flag {
    switch (this) {
      case AppCurrency.inr:
        return '🇮🇳';
      case AppCurrency.usd:
        return '🇺🇸';
      case AppCurrency.eur:
        return '🇪🇺';
      case AppCurrency.gbp:
        return '🇬🇧';
      case AppCurrency.jpy:
        return '🇯🇵';
      case AppCurrency.cad:
        return '🇨🇦';
      case AppCurrency.aud:
        return '🇦🇺';
      case AppCurrency.sgd:
        return '🇸🇬';
      case AppCurrency.aed:
        return '🇦🇪';
      case AppCurrency.cny:
        return '🇨🇳';
    }
  }
}
