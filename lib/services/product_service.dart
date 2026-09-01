import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class ProductService {
  // Loads all products.
  Future<List<Product>> getAllProducts() async {
    return _getProducts(Uri.parse('$host/products'));
  }

  // Loads products in a category.
  Future<List<Product>> getProductsByCategory(String slug) async {
    return _getProducts(Uri.parse('$host/products/category/$slug'));
  }

  // Loads product categories.
  Future<List<ProductCategory>> getCategories() async {
    final response = await http.get(Uri.parse('$host/products/categories'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load categories');
    }

    final decodedResponse = jsonDecode(response.body);
    if (decodedResponse is! List) {
      throw const FormatException('Invalid categories response');
    }

    return decodedResponse
        .map((category) => ProductCategory.fromJson(category))
        .where((category) => category.slug.isNotEmpty)
        .toList();
  }

  // Downloads and parses a product list.
  Future<List<Product>> _getProducts(Uri uri) async {
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load products');
    }

    final decodedResponse = jsonDecode(response.body);
    if (decodedResponse is! Map<String, dynamic>) {
      throw const FormatException('Invalid products response');
    }

    final productsJson = decodedResponse['products'];
    if (productsJson is! List) {
      return const [];
    }

    return productsJson
        .whereType<Map>()
        .map((product) => Product.fromJson(Map<String, dynamic>.from(product)))
        .toList();
  }

  // Loads one product by ID.
  Future<Product> getProductById(int id) async {
    final response = await http.get(Uri.parse('$host/products/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load product details');
    }

    final decodedResponse = jsonDecode(response.body);
    if (decodedResponse is! Map<String, dynamic>) {
      throw const FormatException('Invalid product response');
    }

    return Product.fromJson(decodedResponse);
  }
}
