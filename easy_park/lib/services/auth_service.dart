import 'dart:io';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easy_park/constants/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String nim,
    required String fullName,
    required String dateOfBirth, // format: YYYY-MM-DD
    required String phoneNumber,
    required String address,
  }) async {
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
          'nim': nim,
          'full_name': fullName,
          'date_of_birth': dateOfBirth,
          'phone_number': phoneNumber,
          'address': address,
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

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? nim,
    String? fullName,
    String? dateOfBirth, // format: YYYY-MM-DD
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
      if (nim != null) data['nim'] = nim;
      if (fullName != null) data['full_name'] = fullName;
      if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      debugPrint('Update profile response: $body');

      if (response.statusCode == 200) {
        if (body['user'] != null) {
          prefs.setString('user', jsonEncode(body['user']));
        }

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
      debugPrint('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat memperbarui profil.',
        'error': e.toString(),
      };
    }
  }

  // Fungsi UPLOAD IMAGE - ENHANCED
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    debugPrint('Starting profile image upload...');
    final url = Uri.parse('$apiBaseUrl/upload-profile-image');

    try {
      // Check if file exists and is valid
      if (!await imageFile.exists()) {
        debugPrint('File does not exist at path: ${imageFile.path}');
        return {
          'success': false,
          'message': 'File tidak ditemukan.',
        };
      }

      int fileSize = await imageFile.length();
      debugPrint('File size: ${fileSize / 1024} KB');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        debugPrint('Token not found');
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      debugPrint('Creating multipart request to $url');
      var request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

      // Add the file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // This field name should match what your API expects
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );

      debugPrint('Sending request...');
      var streamedResponse = await request.send();
      var responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('Response status: ${streamedResponse.statusCode}');
      debugPrint('Response body: $responseBody');

      final body = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        // Extract profile photo URL, handling different possible response formats
        String? profilePhotoUrl;

        // Check different possible locations for the profile photo URL
        if (body['user'] != null && body['user']['profile_photo_url'] != null) {
          profilePhotoUrl = body['user']['profile_photo_url'];
        } else if (body['profile_photo_url'] != null) {
          profilePhotoUrl = body['profile_photo_url'];
        } else if (body['data'] != null &&
            body['data']['profile_photo_url'] != null) {
          profilePhotoUrl = body['data']['profile_photo_url'];
        } else if (body['url'] != null) {
          profilePhotoUrl = body['url'];
        }

        debugPrint('Extracted profile photo URL: $profilePhotoUrl');

        // Update user data in SharedPreferences with new image URL
        if (body['user'] != null) {
          await prefs.setString('user', jsonEncode(body['user']));
          debugPrint('Updated user data in SharedPreferences');
        } else if (profilePhotoUrl != null) {
          // If user object not in response but we have the URL, update it manually
          String? userData = prefs.getString('user');
          if (userData != null) {
            Map<String, dynamic> user = jsonDecode(userData);
            user['profile_photo_url'] = profilePhotoUrl;
            await prefs.setString('user', jsonEncode(user));
            debugPrint('Manually updated profile_photo_url in user data');
          }
        }

        return {
          'success': true,
          'message': body['message'] ?? 'Gambar berhasil diupload',
          'user': body['user'],
          'profile_photo_url': profilePhotoUrl,
        };
      } else {
        debugPrint('Upload failed with status: ${streamedResponse.statusCode}');
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal upload gambar',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat upload gambar: $e',
        'error': e.toString(),
      };
    }
  }

  // Fungsi GET PROFILE
  static Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$apiBaseUrl/profile');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      debugPrint('Get profile response: $body');

      if (response.statusCode == 200) {
        // Update data user di SharedPreferences
        if (body['user'] != null) {
          prefs.setString('user', jsonEncode(body['user']));
        }

        return {
          'success': true,
          'message': body['message'] ?? 'Profil berhasil diambil',
          'user': body['user'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil profil',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil profil.',
        'error': e.toString(),
      };
    }
  }
}