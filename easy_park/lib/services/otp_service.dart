import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_park/constants/api_config.dart';
import 'package:flutter/foundation.dart';

class OtpService {
  // Send OTP to email
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/send-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      debugPrint('Send OTP request: email=$email');
      debugPrint('Send OTP response: ${response.statusCode} - ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': result['message'] ?? 'OTP terkirim ke email',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Gagal mengirim OTP (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Send OTP error: $e');
      return {
        'success': false,
        'message': 'Gagal mengirim OTP: $e',
      };
    }
  }

  // Verify OTP code
  static Future<Map<String, dynamic>> verifyOtp(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/verify-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      debugPrint('Verify OTP request: email=$email, code=$code');
      debugPrint('Verify OTP response: ${response.statusCode} - ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': result['message'] ?? 'OTP berhasil diverifikasi',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'OTP tidak valid atau sudah kedaluwarsa (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      return {
        'success': false,
        'message': 'Gagal memverifikasi OTP: $e',
      };
    }
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword(
      String email, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/reset-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      debugPrint('Reset password request: email=$email');
      debugPrint('Reset password response: ${response.statusCode} - ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': result['message'] ?? 'Password berhasil direset',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Gagal mereset password (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Reset password error: $e');
      return {
        'success': false,
        'message': 'Gagal mereset password: $e',
      };
    }
  }
}