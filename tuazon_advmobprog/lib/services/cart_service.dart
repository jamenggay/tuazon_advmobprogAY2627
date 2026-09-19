import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // loads carts for signed in user.
  Future<List<Cart>> getCartsByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load user cart');
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List cartsJson = data['carts'] ?? [];
    return cartsJson.map((json) => Cart.fromJson(json)).toList();
  }

  // Adds a product to a cart.
  Future<Cart> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    // Sends the cart data to the API.
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {
            'id': productId,
            'quantity': quantity,
          }
        ],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add product to cart');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return Cart.fromJson(data);
  }
}
