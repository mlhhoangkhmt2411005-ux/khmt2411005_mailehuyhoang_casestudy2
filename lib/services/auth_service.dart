import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class AuthService {
  static User? currentUser;

  static Future<bool> login(String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });
      final token = response['token'];
      final userJson = response['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      await prefs.setString(AppConstants.userKey, jsonEncode(userJson));

      currentUser = User.fromJson(userJson);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> register(String fullName, String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/register', {
        'fullName': fullName,
        'email': email,
        'password': password,
      });
      final token = response['token'];
      final userJson = response['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      await prefs.setString(AppConstants.userKey, jsonEncode(userJson));

      currentUser = User.fromJson(userJson);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    currentUser = null;
  }

  static Future<bool> checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userStr = prefs.getString(AppConstants.userKey);

    if (token != null && userStr != null) {
      try {
        currentUser = User.fromJson(jsonDecode(userStr));
        return true;
      } catch (_) {
        await logout();
        return false;
      }
    }
    return false;
  }
}
