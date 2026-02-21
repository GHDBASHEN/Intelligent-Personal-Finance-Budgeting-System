import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  // Using a mockable public API for demonstration
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest/';

  Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    try {
      final response = await http.get(Uri.parse('\$_baseUrl\$baseCurrency'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load exchange rates');
      }
    } catch (e) {
      // Return mock data if API fails or for simulation
      return {
        'base': baseCurrency,
        'rates': {
          'USD': 1.0,
          'EUR': 0.92,
          'GBP': 0.79,
          'LKR': 310.0,
          'INR': 83.0,
        }
      };
    }
  }

  double convert(double amount, double rate) {
    return amount * rate;
  }
}
