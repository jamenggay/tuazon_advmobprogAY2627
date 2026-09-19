import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';

class UserService {
  Map<String, dynamic> data = {};

  // tells the app which login was used so the profile shows the right details.
  static const String loginTypeDummyJson = 'dummyjson';
  static const String loginTypeFirebase = 'firebase';

  final fb_auth.FirebaseAuth firebaseAuth = fb_auth.FirebaseAuth.instance;

  // turns an error into a short message the user can understand.
  static String friendlyError(Object error) {
    // firebase sends a code we can check.
    if (error is fb_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'email-already-in-use':
          return 'That email already has an account.';
        case 'weak-password':
          return 'Password is too weak. Please use a stronger one.';
        case 'operation-not-allowed':
          return 'Email sign in is turned off for this app.';
        case 'too-many-requests':
          return 'Too many tries. Please wait a moment.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'requires-recent-login':
          return 'Please sign in again before doing this.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }

    final text = error.toString();

    // dummyjson puts the reason inside a json body.
    if (text.contains('{') && text.contains('message')) {
      try {
        final body = jsonDecode(text.substring(text.indexOf('{')))
            as Map<String, dynamic>;
        final message = body['message'] as String?;
        if (message != null && message.isNotEmpty) return message;
      } catch (_) {
        // not a json body, use the general message below.
      }
    }

    // no signal or the server cannot be reached.
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException')) {
      return 'No internet connection.';
    }

    return 'Something went wrong. Please try again.';
  }

  // ---------------- DummyJSON login (API call) ----------------

  Future<Map<String, dynamic>> loginUser(
      String username, String password) async {
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
      // remember that this session came from dummyjson.
      data['loginType'] = loginTypeDummyJson;
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  // saves user data on the device.
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
    // save the extra sign up fields too.
    await prefs.setInt('age', user.age);
    await prefs.setString('contactNo', user.contactNo);
    await prefs.setString('loginType', user.loginType);

    // save the available authentication token.
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  // reads saved user data.
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
      'age': prefs.getInt('age') ?? 0,
      'contactNo': prefs.getString('contactNo') ?? '',
      'loginType': prefs.getString('loginType') ?? '',
      'token':
          prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  // builds a user from saved data.
  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  // reads which login was used, dummyjson or firebase.
  Future<String> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') ?? '';
  }

  // checks whether a user is signed in.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = prefs.getString('loginType') ?? '';

    // firebase keeps its own session, so ask the sdk instead of the token.
    if (loginType == loginTypeFirebase) {
      return firebaseAuth.currentUser != null;
    }

    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // removes saved user data.
  Future<void> logout() async {
    try {
      // sign out from firebase too if that was the login used.
      if (firebaseAuth.currentUser != null) {
        await firebaseAuth.signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // ---------------- Firebase Auth (SDK) ----------------

  fb_auth.User? get currentUser => firebaseAuth.currentUser;

  Stream<fb_auth.User?> get authStateChanges => firebaseAuth.authStateChanges();

  // signs in using firebase then saves the session on the device.
  Future<fb_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // firebase gives a token that refreshes on its own.
    final token = await credential.user?.getIdToken() ?? '';

    // keep whatever profile details were saved before this sign in.
    final saved = await getUserData();

    await saveUserData({
      'id': saved['id'],
      'username': credential.user?.displayName ?? saved['username'],
      'email': credential.user?.email ?? '',
      'firstName': saved['firstName'],
      'lastName': saved['lastName'],
      'gender': saved['gender'],
      'image': credential.user?.photoURL ?? '',
      'accessToken': token,
      'refreshToken': '',
      'age': saved['age'],
      'contactNo': saved['contactNo'],
      'loginType': loginTypeFirebase,
    });

    return credential;
  }

  // creates a firebase account and saves the sign up details.
  Future<fb_auth.UserCredential> createAccount({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    String username = '',
    int age = 0,
    String contactNo = '',
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // firebase only stores a display name, so use the username for it.
    if (username.isNotEmpty) {
      await credential.user?.updateDisplayName(username);
    }

    final token = await credential.user?.getIdToken() ?? '';

    // the rest of the sign up fields are saved on the device.
    await saveUserData({
      'id': 0,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': '',
      'image': '',
      'accessToken': token,
      'refreshToken': '',
      'age': age,
      'contactNo': contactNo,
      'loginType': loginTypeFirebase,
    });

    return credential;
  }

  // signs out from firebase and clears the saved session.
  Future<void> signOut() async {
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // changes the display name and updates the saved copy.
  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);

    // keep the saved data in sync with firebase.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  // deletes the account then clears the saved session.
  // the email and password are optional, they are only used to check
  // the account again when firebase asks for a recent login.
  Future<void> deleteAccount({
    String email = '',
    String password = '',
  }) async {
    if (email.isNotEmpty && password.isNotEmpty) {
      final fb_auth.AuthCredential credential =
          fb_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await currentUser!.reauthenticateWithCredential(credential);
    }

    await currentUser!.delete();
    await firebaseAuth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // changes the password after checking the current one.
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final fb_auth.AuthCredential credential =
        fb_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
