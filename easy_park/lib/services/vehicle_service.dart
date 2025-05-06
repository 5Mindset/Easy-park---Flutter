import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'local_db_service.dart';
import 'package:easy_park/constants/api_config.dart';

class VehicleService {
 
  // Helper method to get auth token
  static Future<String?> _getToken() async {
    final savedUser = await LocalDbService.getLogin(); // Assumes LocalDbService from your AuthService
    return savedUser?['token'] as String?;
  }

  // --- Vehicle Endpoints ---

  /// Fetch all vehicles with model and user relationships
  static Future<Map<String, dynamic>> getVehicles() async {
    final url = Uri.parse('$apiBaseUrl/vehicles');
    try {
      final token = await _getToken();
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
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Berhasil mengambil daftar kendaraan',
          'data': body, // List of vehicles with model and user
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil daftar kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil daftar kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Create a new vehicle
  static Future<Map<String, dynamic>> createVehicle({
    required String plateNumber,
    required int vehicleModelId,
    required int userId,
    File? stnkImage,
    String? qrCode,
  }) async {
    final url = Uri.parse('$apiBaseUrl/vehicles');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      if (stnkImage != null) {
        // Check file size (max 2MB)
        final fileSize = await stnkImage.length();
        if (fileSize > 2 * 1024 * 1024) {
          return {
            'success': false,
            'message': 'Ukuran gambar terlalu besar (maksimum 2MB).',
          };
        }

        // Multipart request for image upload
        final request = http.MultipartRequest('POST', url)
          ..headers.addAll({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          })
          ..fields.addAll({
            'plate_number': plateNumber,
            'vehicle_model_id': vehicleModelId.toString(),
            'user_id': userId.toString(),
            if (qrCode != null) 'qr_code': qrCode,
          })
          ..files.add(
            await http.MultipartFile.fromPath(
              'stnk_image',
              stnkImage.path,
              filename: path.basename(stnkImage.path),
            ),
          );

        final streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();
        final body = jsonDecode(responseBody);

        if (streamedResponse.statusCode == 201) {
          return {
            'success': true,
            'message': 'Kendaraan berhasil didaftarkan',
            'data': body,
          };
        } else {
          return {
            'success': false,
            'message': body['message'] ?? 'Gagal mendaftarkan kendaraan',
            'errors': body['errors'] ?? {},
          };
        }
      } else {
        // JSON request without image
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'plate_number': plateNumber,
            'vehicle_model_id': vehicleModelId,
            'user_id': userId,
            if (qrCode != null) 'qr_code': qrCode,
          }),
        );

        final body = jsonDecode(response.body);
        if (response.statusCode == 201) {
          return {
            'success': true,
            'message': 'Kendaraan berhasil didaftarkan',
            'data': body,
          };
        } else {
          return {
            'success': false,
            'message': body['message'] ?? 'Gagal mendaftarkan kendaraan',
            'errors': body['errors'] ?? {},
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mendaftarkan kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Fetch a specific vehicle by ID
  static Future<Map<String, dynamic>> getVehicle(int id) async {
    final url = Uri.parse('$apiBaseUrl/vehicles/$id');
    try {
      final token = await _getToken();
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
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Berhasil mengambil detail kendaraan',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil detail kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil detail kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Update a vehicle
  static Future<Map<String, dynamic>> updateVehicle({
    required int id,
    required String plateNumber,
    required int vehicleModelId,
    required int userId,
    File? stnkImage,
    String? qrCode,
  }) async {
    final url = Uri.parse('$apiBaseUrl/vehicles/$id');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      if (stnkImage != null) {
        // Check file size (max 2MB)
        final fileSize = await stnkImage.length();
        if (fileSize > 2 * 1024 * 1024) {
          return {
            'success': false,
            'message': 'Ukuran gambar terlalu besar (maksimum 2MB).',
          };
        }

        // Multipart request for image upload
        final request = http.MultipartRequest('PUT', url)
          ..headers.addAll({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          })
          ..fields.addAll({
            'plate_number': plateNumber,
            'vehicle_model_id': vehicleModelId.toString(),
            'user_id': userId.toString(),
            if (qrCode != null) 'qr_code': qrCode,
          })
          ..files.add(
            await http.MultipartFile.fromPath(
              'stnk_image',
              stnkImage.path,
              filename: path.basename(stnkImage.path),
            ),
          );

        final streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();
        final body = jsonDecode(responseBody);

        if (streamedResponse.statusCode == 200) {
          return {
            'success': true,
            'message': 'Kendaraan berhasil diperbarui',
            'data': body,
          };
        } else {
          return {
            'success': false,
            'message': body['message'] ?? 'Gagal memperbarui kendaraan',
            'errors': body['errors'] ?? {},
          };
        }
      } else {
        // JSON request without image
        final response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'plate_number': plateNumber,
            'vehicle_model_id': vehicleModelId,
            'user_id': userId,
            if (qrCode != null) 'qr_code': qrCode,
          }),
        );

        final body = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Kendaraan berhasil diperbarui',
            'data': body,
          };
        } else {
          return {
            'success': false,
            'message': body['message'] ?? 'Gagal memperbarui kendaraan',
            'errors': body['errors'] ?? {},
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat memperbarui kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Delete a vehicle
  static Future<Map<String, dynamic>> deleteVehicle(int id) async {
    final url = Uri.parse('$apiBaseUrl/vehicles/$id');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Kendaraan berhasil dihapus',
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal menghapus kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat menghapus kendaraan.',
        'error': e.toString(),
      };
    }
  }

  // --- Vehicle Brand Endpoints ---

  /// Fetch all vehicle brands
  static Future<Map<String, dynamic>> getVehicleBrands() async {
    final url = Uri.parse('$apiBaseUrl/vehicle-brands');
    try {
      final token = await _getToken();
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
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Berhasil mengambil daftar merek kendaraan',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil daftar merek kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil daftar merek kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Create a new vehicle brand
  static Future<Map<String, dynamic>> createVehicleBrand(String name) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-brands');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Merek kendaraan berhasil dibuat',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal membuat merek kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat membuat merek kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Fetch a specific vehicle brand
  static Future<Map<String, dynamic>> getVehicleBrand(int id) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-brands/$id');
    try {
      final token = await _getToken();
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
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Berhasil mengambil detail merek kendaraan',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil detail merek kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil detail merek kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Update a vehicle brand
  static Future<Map<String, dynamic>> updateVehicleBrand(int id, String name) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-brands/$id');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Merek kendaraan berhasil diperbarui',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal memperbarui merek kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat memperbarui merek kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Delete a vehicle brand
  static Future<Map<String, dynamic>> deleteVehicleBrand(int id) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-brands/$id');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Merek kendaraan berhasil dihapus',
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal menghapus merek kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat menghapus merek kendaraan.',
        'error': e.toString(),
      };
    }
  }

  // --- Vehicle Model Endpoints ---

  /// Fetch all vehicle models with brand and type relationships
  static Future<Map<String, dynamic>> getVehicleModels() async {
    final url = Uri.parse('$apiBaseUrl/vehicle-models');
    try {
      final token = await _getToken();
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
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Berhasil mengambil daftar model kendaraan',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil daftar model kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil daftar model kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Create a new vehicle model
  static Future<Map<String, dynamic>> createVehicleModel({
    required String name,
    required int vehicleBrandId,
    required int vehicleTypeId,
  }) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-models');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'vehicle_brand_id': vehicleBrandId,
          'vehicle_type_id': vehicleTypeId,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Model kendaraan berhasil dibuat',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal membuat model kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat membuat model kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Fetch a specific vehicle model
  static Future<Map<String, dynamic>> getVehicleModel(int id) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-models/$id');
    try {
      final token = await _getToken();
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
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Berhasil mengambil detail model kendaraan',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil detail model kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil detail model kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Update a vehicle model
  static Future<Map<String, dynamic>> updateVehicleModel({
    required int id,
    required String name,
    required int vehicleBrandId,
    required int vehicleTypeId,
  }) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-models/$id');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'vehicle_brand_id': vehicleBrandId,
          'vehicle_type_id': vehicleTypeId,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Model kendaraan berhasil diperbarui',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal memperbarui model kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat memperbarui model kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Delete a vehicle model
  static Future<Map<String, dynamic>> deleteVehicleModel(int id) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-models/$id');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Model kendaraan berhasil dihapus',
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal menghapus model kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat menghapus model kendaraan.',
        'error': e.toString(),
      };
    }
  }

  // --- Vehicle Type Endpoints ---

  /// Fetch all vehicle types
  static Future<Map<String, dynamic>> getVehicleTypes() async {
    final url = Uri.parse('$apiBaseUrl/vehicle-types');
    try {
      final token = await _getToken();
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
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Berhasil mengambil daftar tipe kendaraan',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil daftar tipe kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil daftar tipe kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Create a new vehicle type
  static Future<Map<String, dynamic>> createVehicleType(String name) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-types');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Tipe kendaraan berhasil dibuat',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal membuat tipe kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat membuat tipe kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Fetch a specific vehicle type
  static Future<Map<String, dynamic>> getVehicleType(int id) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-types/$id');
    try {
      final token = await _getToken();
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
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Berhasil mengambil detail tipe kendaraan',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil detail tipe kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil detail tipe kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Update a vehicle type
  static Future<Map<String, dynamic>> updateVehicleType(int id, String name) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-types/$id');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Tipe kendaraan berhasil diperbarui',
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal memperbarui tipe kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat memperbarui tipe kendaraan.',
        'error': e.toString(),
      };
    }
  }

  /// Delete a vehicle type
  static Future<Map<String, dynamic>> deleteVehicleType(int id) async {
    final url = Uri.parse('$apiBaseUrl/vehicle-types/$id');
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Tidak ada token ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Tipe kendaraan berhasil dihapus',
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal menghapus tipe kendaraan',
          'errors': body['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat menghapus tipe kendaraan.',
        'error': e.toString(),
      };
    }
  }
}
