import 'package:flutter/material.dart';

class CurrencyProvider extends ChangeNotifier {
  String _currencyCode = 'US';

  String get currencyCode => _currencyCode;

  void setCurrency(String newCurrency) {
    _currencyCode = newCurrency;
    notifyListeners();
  }
}
