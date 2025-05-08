import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/local_db_service.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class VehicleService {
  /// Fetch the list of vehicles for the authenticated user
  static Future<Map<String, dynamic>> getVehicles() async {
    try {
      final savedUser = await LocalDbService.getLogin();
      final token = savedUser?['token'] as String?;

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/my-vehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Unauthorized action. Please log in again.',
          'error': 'Invalid or expired token',
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to fetch vehicles: ${response.statusCode}',
          'error': body['error'] ?? 'No additional error details provided',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching vehicles: $e',
        'error': e.toString(),
      };
    }
  }

  /// Fetch vehicle brands
  static Future<Map<String, dynamic>> getVehicleBrands() async {
    try {
      final savedUser = await LocalDbService.getLogin();
      final token = savedUser?['token'] as String?;

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/vehicle-brands'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Unauthorized action. Please log in again.',
          'error': 'Invalid or expired token',
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to fetch vehicle brands: ${response.statusCode}',
          'error': body['error'] ?? 'No additional error details provided',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching vehicle brands: $e',
        'error': e.toString(),
      };
    }
  }

  /// Fetch vehicle types
  static Future<Map<String, dynamic>> getVehicleTypes() async {
    try {
      final savedUser = await LocalDbService.getLogin();
      final token = savedUser?['token'] as String?;

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/vehicle-types'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Unauthorized action. Please log in again.',
          'error': 'Invalid or expired token',
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to fetch vehicle types: ${response.statusCode}',
          'error': body['error'] ?? 'No additional error details provided',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching vehicle types: $e',
        'error': e.toString(),
      };
    }
  }

  /// Fetch vehicle models by brand and type
  static Future<Map<String, dynamic>> getVehicleModels(int brandId, int typeId) async {
    try {
      final savedUser = await LocalDbService.getLogin();
      final token = savedUser?['token'] as String?;

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/vehicle-models?vehicle_brand_id=$brandId&vehicle_type_id=$typeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Unauthorized action. Please log in again.',
          'error': 'Invalid or expired token',
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to fetch vehicle models: ${response.statusCode}',
          'error': body['error'] ?? 'No additional error details provided',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching vehicle models: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> addVehicle({
  required String plateNumber,
  required int vehicleModelId,
  File? stnkImage,
}) async {
  try {
    final savedUser = await LocalDbService.getLogin();
    final token = savedUser?['token'] as String?;

    if (token == null) {
      return {
        'success': false,
        'message': 'No authentication token found. Please log in again.',
      };
    }

    print('Debug: Token: $token');
    print('Debug: Plate Number: $plateNumber');
    print('Debug: Vehicle Model ID: $vehicleModelId');
    print('Debug: STNK Image Path: ${stnkImage?.path}');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBaseUrl/my-vehicles'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['plate_number'] = plateNumber;
    request.fields['vehicle_model_id'] = vehicleModelId.toString();

    if (stnkImage != null) {
      String extension = stnkImage.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        return {
          'success': false,
          'message': 'Invalid image format. Only JPG, JPEG, or PNG are allowed.',
        };
      }

      request.files.add(await http.MultipartFile.fromPath(
        'stnk_image',
        stnkImage.path,
        contentType: MediaType('image', extension == 'jpg' ? 'jpeg' : extension),
      ));
    }

    // Debug print final data
    print('Debug: Request Headers: ${request.headers}');
    print('Debug: Request Fields: ${request.fields}');
    print('Debug: Request Files: ${request.files.map((f) => f.filename).toList()}');

    // Use http.Client explicitly
    final client = http.Client();
    final streamedResponse = await client.send(request);
    final responseBody = await streamedResponse.stream.bytesToString();

    print('Debug: Response Status: ${streamedResponse.statusCode}');
    print('Debug: Response Body: $responseBody');

    if (streamedResponse.statusCode == 201) {
      try {
        final data = jsonDecode(responseBody);
        return {
          'success': true,
          'data': data,
        };
      } catch (_) {
        return {
          'success': true,
          'data': responseBody,
          'message': 'Vehicle added, but response is not JSON.',
        };
      }
    } else if (streamedResponse.statusCode == 401 || streamedResponse.statusCode == 403) {
      return {
        'success': false,
        'message': 'Unauthorized action. Please log in again.',
        'error': 'Invalid or expired token: $responseBody',
      };
    } else if (streamedResponse.statusCode == 422) {
      final body = jsonDecode(responseBody);
      return {
        'success': false,
        'message': body['message'] ?? 'Validation failed',
        'error': body['errors'] ?? responseBody,
      };
    } else {
      final body = jsonDecode(responseBody);
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to add vehicle: ${streamedResponse.statusCode}',
        'error': body['error'] ?? responseBody,
      };
    }
  } catch (e) {
    print('Debug: Exception: $e');
    return {
      'success': false,
      'message': 'Error adding vehicle: $e',
      'error': e.toString(),
    };
  }
}

/// Delete a vehicle by ID
  static Future<Map<String, dynamic>> deleteVehicle(int id) async {
    try {
      final savedUser = await LocalDbService.getLogin();
      final token = savedUser?['token'] as String?;

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please log in again.',
        };
      }

      print('Debug: Token: $token');
      print('Debug: Deleting vehicle ID: $id');

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/my-vehicles/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Debug: deleteVehicle Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Vehicle deleted successfully',
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Unauthorized action. Please log in again.',
          'error': 'Invalid or expired token',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Vehicle not found or you do not have permission to delete it',
          'error': 'Not found',
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to delete vehicle: ${response.statusCode}',
          'error': body['error'] ?? 'No additional error details provided',
        };
      }
    } catch (e) {
      print('Debug: deleteVehicle Error: $e');
      return {
        'success': false,
        'message': 'Error deleting vehicle: $e',
        'error': e.toString(),
      };
    }
  }
}