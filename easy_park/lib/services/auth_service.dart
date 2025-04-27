// File: lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_park/constants/api_config.dart'; // pastikan path-nya sesuai
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Fungsi REGISTER
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final url = Uri.parse('$apiBaseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Registrasi berhasil',
          'token': body['access_token'],
          'user': body['user'],
          'redirect_to': body['redirect_to'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal registrasi',
          'errors': body['errors'] ?? {}, // kalau ada multiple error
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat menghubungi server.',
        'error': e.toString(),
      };
    }
  }

  // Fungsi LOGIN
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final url = Uri.parse('$apiBaseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan token ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('token', body['access_token']);
        prefs.setString('user', jsonEncode(body['user']));

        return {
          'success': true,
          'message': body['message'] ?? 'Login berhasil',
          'token': body['access_token'],
          'user': body['user'],
          'redirect_to': body['redirect_to'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Login gagal',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat menghubungi server.',
        'error': e.toString(),
      };
    }
  }

  // Fungsi LOGOUT
  static Future<Map<String, dynamic>> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');

      return {
        'success': true,
        'message': 'Logout berhasil',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat logout.',
        'error': e.toString(),
      };
    }
  }

  // Fungsi untuk AUTO LOGIN (cek token di SharedPreferences)
  static Future<Map<String, dynamic>> autoLogin() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? user = prefs.getString('user');

      if (token != null && user != null) {
        return {
          'success': true,
          'message': 'Auto login berhasil',
          'token': token,
          'user': jsonDecode(user),
        };
      } else {
        return {
          'success': false,
          'message': 'Tidak ada sesi login yang ditemukan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat memuat sesi login.',
        'error': e.toString(),
      };
    }
  }

  // Fungsi UPDATE PROFILE
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
  }) async {
    final url = Uri.parse('$apiBaseUrl/update-profile');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (address != null) data['address'] = address;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update data user di SharedPreferences juga
        prefs.setString('user', jsonEncode(body['user']));

        return {
          'success': true,
          'message': body['message'] ?? 'Profil berhasil diperbarui',
          'user': body['user'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal memperbarui profil',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat memperbarui profil.',
        'error': e.toString(),
      };
    }
  }
}
