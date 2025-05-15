import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedVehicle {
  static final SelectedVehicle _instance = SelectedVehicle._internal();
  factory SelectedVehicle() => _instance;
  SelectedVehicle._internal();

  String? _qrCodeUrl;
  Map<String, dynamic>? _vehicle;

  String? get qrCodeUrl => _qrCodeUrl;
  Map<String, dynamic>? get vehicle => _vehicle;

  Future<void> setSelectedVehicle(String qrCodeUrl, Map<String, dynamic> vehicle) async {
    try {
      if (qrCodeUrl.isEmpty || vehicle.isEmpty) {
        print('Error: Invalid QR code URL or vehicle data');
        return;
      }
      print('Setting vehicle: $vehicle'); // Debug print
      _qrCodeUrl = qrCodeUrl;
      _vehicle = vehicle;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_vehicle', jsonEncode(vehicle));
      await prefs.setString('selected_qrcode', qrCodeUrl);
      print('SelectedVehicle updated successfully');
    } catch (e) {
      print('Error setting SelectedVehicle: $e');
    }
  }

  Future<void> clearSelectedVehicle() async {
    try {
      _qrCodeUrl = null;
      _vehicle = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_vehicle');
      await prefs.remove('selected_qrcode');
      print('SelectedVehicle cleared');
    } catch (e) {
      print('Error clearing SelectedVehicle: $e');
    }
  }

  Future<void> loadSelectedVehicle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehicleJson = prefs.getString('selected_vehicle');
      final qrCode = prefs.getString('selected_qrcode');

      print('Raw vehicle JSON: $vehicleJson'); // Debug print
      print('QR Code: $qrCode'); // Debug print

      if (vehicleJson != null && qrCode != null) {
        _vehicle = jsonDecode(vehicleJson) as Map<String, dynamic>?;
        _qrCodeUrl = qrCode;
        print('SelectedVehicle loaded: $_vehicle');
      } else {
        print('No valid SelectedVehicle data found');
      }
    } catch (e) {
      print('Error loading SelectedVehicle: $e');
      _vehicle = null;
      _qrCodeUrl = null;
    }
  }
}