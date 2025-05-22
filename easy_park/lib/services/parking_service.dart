import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_park/constants/api_config.dart';

class ParkingService {
  /// Mencatat kendaraan masuk/keluar tempat parkir (scan QR)
  Future<Map<String, dynamic>?> scanParkirKendaraan({
    required int vehicleId,
    int? parkingAreaId, // optional, default ke 1 di backend
  }) async {
    final url = Uri.parse('$apiBaseUrl/parking-records/scan');
    
    try {
      final Map<String, dynamic> body = {'vehicle_id': vehicleId};
      
      // Tambahkan parking_area_id jika disediakan
      if (parkingAreaId != null) {
        body['parking_area_id'] = parkingAreaId;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('Scan Status: ${response.statusCode}');
      print('Scan Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 409) {
        // Kapasitas tidak mencukupi atau conflict lainnya
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Terjadi kesalahan',
          'status_code': response.statusCode,
        };
      } else if (response.statusCode == 404) {
        // Kendaraan tidak ditemukan
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Kendaraan tidak ditemukan',
          'status_code': response.statusCode,
        };
      } else if (response.statusCode == 422) {
        // Tipe kendaraan tidak ditemukan
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Data kendaraan tidak valid',
          'status_code': response.statusCode,
        };
      } else {
        // Error lainnya
        return {
          'success': false,
          'message': 'Terjadi kesalahan server',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('Error saat scan parkir kendaraan: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server',
        'error': e.toString(),
      };
    }
  }

  /// Method terpisah untuk keluar parkir (jika masih diperlukan)
  Future<Map<String, dynamic>?> keluarParkirKendaraan({
    required int parkingRecordId,
  }) async {
    final url = Uri.parse('$apiBaseUrl/parking-records/$parkingRecordId/exit');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Exit Status: ${response.statusCode}');
      print('Exit Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Gagal keluar parkir',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('Error saat keluar parkir: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server',
        'error': e.toString(),
      };
    }
  }

  /// Cek status parkir kendaraan
  Future<Map<String, dynamic>?> cekStatusParkir({required int vehicleId}) async {
    final url = Uri.parse('$apiBaseUrl/parking-records/status/$vehicleId');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error saat cek status parkir: $e');
    }

    return null;
  }
}