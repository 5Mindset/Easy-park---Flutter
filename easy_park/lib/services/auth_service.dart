import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:easy_park/constants/api_config.dart';
import 'local_db_service.dart';
import 'selected_vehicle.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String nim,
    required String fullName,
    required String dateOfBirth,
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
      debugPrint('Error registering: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat menghubungi server.',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('API login response: ${response.body}');
      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = result['user'];
        final token = result['access_token'];
        final role = user['role'];
        final redirectTo = _mapRoleToRedirect(role);

        // ✅ Bersihkan kendaraan terpilih sebelumnya (jika ada)
        await SelectedVehicle().clearSelectedVehicle();

        // ✅ Simpan login ke database lokal
        await LocalDbService.saveLogin(
          email: user['email'],
          token: token,
          role: role,
          userJson: jsonEncode(user),
        );

        return {
          'success': true,
          'message': result['message'] ?? 'Login berhasil',
          'token': token,
          'user': user,
          'role': role,
          'redirect_to': redirectTo,
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<void> logout() async {
    try {
      final savedUser = await LocalDbService.getLogin();
      final token = savedUser?['token'] as String?;
      if (token != null) {
        await http.post(
          Uri.parse('$apiBaseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }
      await LocalDbService.deleteLogin();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  static Future<Map<String, dynamic>> autoLogin() async {
    try {
      final savedUser = await LocalDbService.getLogin();
      debugPrint('Saved user from LocalDbService: $savedUser');
      if (savedUser == null) {
        return {'success': false, 'message': 'No user data found'};
      }

      final email = savedUser['email'] as String?;
      final token = savedUser['token'] as String?;
      final userJson = savedUser['user_json'] as String?;
      if (email == null || token == null || userJson == null) {
        await LocalDbService.deleteLogin();
        return {
          'success': false,
          'message': 'Incomplete user data in LocalDbService'
        };
      }

      final storedUser = jsonDecode(userJson);
      final storedRole = storedUser['role'];

      // Attempt API call to validate token
      final response = await http.get(
        Uri.parse('$apiBaseUrl/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        return http.Response('Request timed out', 504);
      });

      debugPrint(
          'API user response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final user = result['user'] ?? result['data']?['user'];
        if (user == null) {
          await LocalDbService.deleteLogin();
          return {'success': false, 'message': 'Invalid user data from API'};
        }

        final role = user['role'] ?? storedRole;
        if (role == null) {
          await LocalDbService.deleteLogin();
          return {'success': false, 'message': 'No role found in user data'};
        }

        String redirectTo;
        switch (role) {
          case 'admin':
            redirectTo = 'adminHome';
            break;
          case 'petugas':
            redirectTo = 'petugasHome';
            break;
          case 'mahasiswa':
            redirectTo = 'Bottom_Navigation';
            break;
          default:
            redirectTo = 'home';
        }

        // Update LocalDbService with latest user data
        await LocalDbService.saveLogin(
          email: email,
          token: token,
          role: role,
          userJson: jsonEncode(user),
        );
        debugPrint('Updated LocalDbService: email=$email, role=$role');

        return {
          'success': true,
          'message': 'Auto-login successful',
          'token': token,
          'user': user,
          'role': role,
          'redirect_to': redirectTo,
        };
      } else {
        // Fallback to stored user data if API call fails
        debugPrint('Falling back to stored user data due to API failure');
        if (storedRole != null) {
          String redirectTo;
          switch (storedRole) {
            case 'admin':
              redirectTo = 'adminHome';
              break;
            case 'petugas':
              redirectTo = 'petugasHome';
              break;
            case 'mahasiswa':
              redirectTo = 'Bottom_Navigation';
              break;
            default:
              redirectTo = 'home';
          }

          return {
            'success': true,
            'message': 'Auto-login using stored data',
            'token': token,
            'user': storedUser,
            'role': storedRole,
            'redirect_to': redirectTo,
          };
        }

        await LocalDbService.deleteLogin();
        return {
          'success': false,
          'message':
              'Invalid or expired token: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('Auto-login error: $e');
      await LocalDbService.deleteLogin();
      return {
        'success': false,
        'message': 'Auto-login failed: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? nim,
    String? fullName, // Add fullName parameter
    String? dateOfBirth,
  }) async {
    final url = Uri.parse('$apiBaseUrl/update-profile');

    try {
      final savedUser = await LocalDbService.getLogin();
      final token = savedUser?['token'] as String?;
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (address != null) data['address'] = address;
      if (nim != null) data['nim'] = nim;
      if (fullName != null) data['full_name'] = fullName; // Send full_name
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
          await LocalDbService.saveLogin(
            email: body['user']['email'] ?? savedUser?['email'] ?? '',
            token: token,
            role: savedUser?['role'] ?? 'mahasiswa',
            userJson: jsonEncode(body['user']),
          );
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

  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    debugPrint('Starting profile image upload...');
    final url = Uri.parse('$apiBaseUrl/upload-profile-image');

    try {
      final savedUser = await LocalDbService.getLogin();
      final token = savedUser?['token'] as String?;
      if (token == null) {
        debugPrint('Token not found');
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      // Check file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        debugPrint('File too large: ${fileSize / 1024} KB');
        return {
          'success': false,
          'message': 'Ukuran file terlalu besar (maksimum 5MB).',
        };
      }

      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        })
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            filename: path.basename(imageFile.path),
          ),
        );

      debugPrint('Sending request...');
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('Response status: ${streamedResponse.statusCode}');
      debugPrint('Response body: $responseBody');

      final body = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        String? profilePhotoUrl;
        if (body['user']?['profile_photo_url'] != null) {
          profilePhotoUrl = body['user']['profile_photo_url'];
        } else if (body['profile_photo_url'] != null) {
          profilePhotoUrl = body['profile_photo_url'];
        } else if (body['data']?['profile_photo_url'] != null) {
          profilePhotoUrl = body['data']['profile_photo_url'];
        } else if (body['url'] != null) {
          profilePhotoUrl = body['url'];
        }

        debugPrint('Extracted profile photo URL: $profilePhotoUrl');

        if (body['user'] != null) {
          await LocalDbService.saveLogin(
            email: body['user']['email'] ?? savedUser?['email'] ?? '',
            token: token,
            role: savedUser?['role'] ?? 'mahasiswa',
            userJson: jsonEncode(body['user']),
          );
        } else if (profilePhotoUrl != null) {
          final currentUserJson = savedUser?['user_json'] as String?;
          if (currentUserJson != null) {
            final user = jsonDecode(currentUserJson);
            user['profile_photo_url'] = profilePhotoUrl;
            await LocalDbService.saveLogin(
              email: savedUser?['email'] ?? '',
              token: token,
              role: savedUser?['role'] ?? 'mahasiswa',
              userJson: jsonEncode(user),
            );
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
        'message': 'Terjadi kesalahan saat upload gambar.',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$apiBaseUrl/profile');

    try {
      final savedUser = await LocalDbService.getLogin();
      final token = savedUser?['token'] as String?;
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
        if (body['user'] != null) {
          await LocalDbService.saveLogin(
            email: body['user']['email'] ?? savedUser?['email'] ?? '',
            token: token,
            role: savedUser?['role'] ?? 'mahasiswa',
            userJson: jsonEncode(body['user']),
          );
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

  static String _mapRoleToRedirect(String role) {
    switch (role.toLowerCase()) {
      case 'mahasiswa':
        return 'Bottom_Navigation';
      case 'petugas':
        return 'petugasHome';
      case 'admin':
        return 'adminHome';
      default:
        return 'login';
    }
  }
}
