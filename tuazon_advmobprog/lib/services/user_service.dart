import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// saves user data on the device.
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    // save the available authentication token.
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  /// reads saved user data.
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ??
          prefs.getString('accessToken') ??
          '',
    };
  }

  /// builds a user from saved data.
  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  /// checks whether a user is signed in.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// removes saved user data.
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  final fb_auth.FirebaseAuth firebaseAuth = fb_auth.FirebaseAuth.instance;

  fb_auth.User? get currentUser => firebaseAuth.currentUser;

  Stream<fb_auth.User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<fb_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<fb_auth.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
