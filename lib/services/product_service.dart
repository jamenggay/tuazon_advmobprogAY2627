import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class ProductService {
  // Call API to get all products
  Future<List<Product>> getAllProducts() async {
    return _getProducts(Uri.parse('$host/products'));
  }

  /// Products belonging to a single category.
  // Call API to get products by category slug
  Future<List<Product>> getProductsByCategory(String slug) async {
    return _getProducts(Uri.parse('$host/products/category/$slug'));
  }

  // Call API to get list of categories
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

  // Helper method to download and parse product list data
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

  // Call API to get a single product details by id
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