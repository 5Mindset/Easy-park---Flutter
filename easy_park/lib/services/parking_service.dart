import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_park/constants/api_config.dart';

class ParkingService {
  /// Mencatat kendaraan masuk ke tempat parkir tanpa token (public)
  Future<Map<String, dynamic>?> scanParkirKendaraan({required int vehicleId}) async {
  final url = Uri.parse('$apiBaseUrl/parking-records/scan');
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'vehicle_id': vehicleId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // hasil akan mengandung key: message / status
    }
  } catch (e) {
    print('Error saat scan parkir kendaraan: $e');
  }

  return null;
}


  Future<bool> keluarParkirKendaraan({
    required int parkingRecordId,
  }) async {
    final url = Uri.parse('$apiBaseUrl/parking-records/$parkingRecordId/exit');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Exit Status: ${response.statusCode}');
    print('Exit Body: ${response.body}');

    return response.statusCode == 200;
  }
}
