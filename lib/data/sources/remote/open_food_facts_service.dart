import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  Future<String?> getProductName(String barcode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$barcode.json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          final productName = product['product_name'] ?? product['product_name_en'] ?? '';
          final brands = product['brands'] ?? '';
          
          if (productName.toString().isNotEmpty) {
             if (brands.toString().isNotEmpty) {
                 return '$brands $productName'.trim();
             }
             return productName.toString().trim();
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
