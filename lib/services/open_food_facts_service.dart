import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenFoodFactsProduct {
  OpenFoodFactsProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.quantity,
    required this.categories,
    required this.ingredientsText,
  });

  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String quantity;
  final List<String> categories;
  final String ingredientsText;
}

class OpenFoodFactsService {
  static const _host = 'world.openfoodfacts.org';

  Future<OpenFoodFactsProduct?> lookupProduct(String barcode) async {
    final url = Uri.https(_host, '/api/v0/product/$barcode.json');

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 10), onTimeout: () => http.Response('', 408));

    if (response.statusCode != 200) {
      return null;
    }

    final parsed = json.decode(response.body);
    if (parsed is! Map<String, dynamic>) {
      return null;
    }

    final status = parsed['status'] as int?;
    if (status != 1) {
      return null;
    }

    final product = parsed['product'] as Map<String, dynamic>?;
    if (product == null) {
      return null;
    }

    final rawName = product['product_name'] as String? ?? '';
    final rawBrand = product['brands'] as String? ?? '';
    final imageUrl = product['image_front_small_url'] as String? ?? '';
    final quantity = product['quantity'] as String? ?? '';
    final categories = (product['categories_tags'] as List<dynamic>?)
            ?.whereType<String>()
            .map((tag) => tag.replaceFirst('en:', '').replaceAll('-', ' '))
            .toList() ??
        [];
    final ingredientsText = product['ingredients_text'] as String? ?? '';

    return OpenFoodFactsProduct(
      barcode: barcode,
      name: rawName,
      brand: rawBrand.split(',').first.trim(),
      imageUrl: imageUrl,
      quantity: quantity,
      categories: categories,
      ingredientsText: ingredientsText,
    );
  }
}
