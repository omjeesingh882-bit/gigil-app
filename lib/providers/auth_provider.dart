import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  bool _isInit = false;
  bool get isInit => _isInit;

  final String baseUrl = 'https://gigil-backend.onrender.com/api/auth'; // Production server

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(data['user']));
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      print(e);
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(data['user']));
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      print(e);
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithPhoneOTP(String phone, String otp) async {
    // Mock OTP Login
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    if (otp == '1234') { // Mock acceptable OTP
      // Create a mock user since we skip backend for this demo
      _token = 'mock_phone_token_${DateTime.now().millisecondsSinceEpoch}';
      _user = User(
        id: 'phone_$phone',
        username: phone,
        email: '$phone@gigil.app',
        avatar: '',
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(_user!.toJson()));
    } else {
      _isLoading = false;
      notifyListeners();
      throw Exception('Invalid OTP. Use 1234');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['tempPassword'];
      } else {
        throw Exception(data['msg'] ?? 'Password reset failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token') || !prefs.containsKey('user')) {
      _isInit = true;
      notifyListeners();
      return false;
    }
    
    _token = prefs.getString('token');
    final userData = jsonDecode(prefs.getString('user')!);
    _user = User.fromJson(userData);
    _isInit = true;
    notifyListeners();
    return true;
  }
}
