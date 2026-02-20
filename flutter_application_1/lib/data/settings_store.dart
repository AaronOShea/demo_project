import 'package:flutter/foundation.dart';

class SettingsStore extends ChangeNotifier {
  String _currency = 'EUR';
  double _defaultMonthlyIncome = 3000;
  double _payAmount = 0;
  String _payFrequency = 'monthly'; // 'weekly' | 'biweekly' | 'monthly'

  String get currency => _currency;

  double get defaultMonthlyIncome => _defaultMonthlyIncome;
  set defaultMonthlyIncome(double v) {
    if (_defaultMonthlyIncome == v) return;
    _defaultMonthlyIncome = v;
    notifyListeners();
  }

  void setDefaultMonthlyIncome(double v) {
    defaultMonthlyIncome = v;
  }

  double get payAmount => _payAmount;
  String get payFrequency => _payFrequency;

  void setPay(double amount, String frequency) {
    _payAmount = amount;
    _payFrequency = frequency;
    notifyListeners();
  }

  /// Income used across the app: from pay (amount × frequency) if set, else default monthly.
  double get effectiveMonthlyIncome {
    if (_payAmount > 0) {
      switch (_payFrequency) {
        case 'weekly':
          return _payAmount * (52 / 12);
        case 'biweekly':
          return _payAmount * (26 / 12);
        case 'monthly':
        default:
          return _payAmount;
      }
    }
    return _defaultMonthlyIncome;
  }

  set currency(String value) {
    if (_currency == value) return;
    _currency = value;
    notifyListeners();
  }

  void setCurrency(String value) {
    currency = value;
  }

  /// Currency symbol for display (e.g. $, €, £).
  String get currencySymbol {
    switch (_currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return _currency;
    }
  }

  /// Full label e.g. "€ EUR".
  String get currencyLabel {
    switch (_currency) {
      case 'USD':
        return '\$ USD';
      case 'EUR':
        return '€ EUR';
      case 'GBP':
        return '£ GBP';
      default:
        return _currency;
    }
  }
}
