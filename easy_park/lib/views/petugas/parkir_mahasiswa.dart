import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/parking_service.dart';

class ParkirMahasiswa extends StatefulWidget {
  const ParkirMahasiswa({Key? key}) : super(key: key);

  @override
  State<ParkirMahasiswa> createState() => _ParkirMahasiswaState();
}

class _ParkirMahasiswaState extends State<ParkirMahasiswa> {
  String? scannedCode;
  bool _isProcessing = false; // Prevent multiple scans

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; // Prevent multiple scans
    
    final List<Barcode> barcodes = capture.barcodes;
    final String? code = barcodes.isNotEmpty ? barcodes.first.rawValue : null;

    if (code != null && code != scannedCode) {
      setState(() {
        scannedCode = code;
        _isProcessing = true;
      });

      // Tampilkan hasil scan di console
      print('Scan Results: $code');

      // Ambil ID dari URL (contoh: http://192.168.1.9:8000/vehicles/22)
      final uri = Uri.tryParse(code);
      if (uri == null || uri.pathSegments.isEmpty) {
        _showErrorDialog('Format URL tidak valid.');
        _resetProcessing();
        return;
      }

      final id = uri.pathSegments.last;

      try {
        final response = await http.get(
          Uri.parse('$apiBaseUrl/vehicles/$id'),
        );

        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Cek apakah kendaraan sedang parkir
          final parkingRecord = data['latest_parking_record'];
          final isParked =
              parkingRecord != null && parkingRecord['exit_time'] == null;

          if (isParked) {
            _showExitConfirmationDialog(
              vehicleId: int.parse(id),
              plate: data['plate_number'] ?? '-',
            );
          } else {
            _showVehicleInfoDialog(
              vehicleId: int.parse(id),
              type: data['model']?['vehicle_type']?['name'] ?? '-',
              brand: data['model']?['vehicle_brand']?['name'] ?? '-',
              plate: data['plate_number'] ?? '-',
              model: data['model']?['name'] ?? '-',
            );
          }
        } else {
          _showErrorDialog(
              'Gagal mengambil data kendaraan. Status: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorDialog('Terjadi kesalahan: $e');
      }
    }
  }

  void _resetProcessing() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              _resetProcessing();
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sukses'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              _resetProcessing();
            },
          ),
        ],
      ),
    );
  }

  void _showExitConfirmationDialog({
    required int vehicleId,
    required String plate,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: Text('Kendaraan dengan plat $plate akan keluar parkir?'),
        actions: [
          TextButton(
            child: const Text('BATAL'),
            onPressed: () {
              Navigator.of(context).pop();
              _resetProcessing();
            },
          ),
          ElevatedButton(
            child: const Text('KELUAR'),
            onPressed: () async {
              Navigator.of(context).pop(); // Tutup dialog
              
              // Gunakan scanParkirKendaraan untuk keluar (auto-detect)
              final result = await ParkingService().scanParkirKendaraan(
                vehicleId: vehicleId,
              );

              if (result != null) {
                if (result['success'] == false) {
                  _showErrorDialog(result['message'] ?? 'Gagal keluar parkir');
                } else {
                  _showSuccessDialog(result['message'] ?? 'Kendaraan berhasil keluar parkir');
                }
              } else {
                _showErrorDialog('Tidak dapat terhubung ke server');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showVehicleInfoDialog({
    required int vehicleId,
    required String type,
    required String brand,
    required String plate,
    required String model,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Informasi Kendaraan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Tipe', type),
            _buildInfoRow('Brand', brand),
            _buildInfoRow('Plat', plate),
            _buildInfoRow('Model', model),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('TOLAK'),
            onPressed: () {
              Navigator.of(context).pop();
              _resetProcessing();
            },
          ),
          ElevatedButton(
            child: const Text('TERIMA'),
            onPressed: () async {
              Navigator.of(context).pop(); // Tutup dialog
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Memproses...'),
                    ],
                  ),
                ),
              );

              final result = await ParkingService().scanParkirKendaraan(
                vehicleId: vehicleId,
              );

              // Close loading dialog
              Navigator.of(context).pop();

              if (result != null) {
                if (result['success'] == false) {
                  // Handle specific error cases
                  String errorMessage = result['message'] ?? 'Terjadi kesalahan';
                  
                  if (result['status_code'] == 409) {
                    // Kapasitas tidak mencukupi
                    _showErrorDialog('⚠️ $errorMessage');
                  } else if (result['status_code'] == 404) {
                    // Kendaraan tidak ditemukan
                    _showErrorDialog('❌ $errorMessage');
                  } else if (result['status_code'] == 422) {
                    // Data tidak valid
                    _showErrorDialog('⚠️ $errorMessage');
                  } else {
                    _showErrorDialog(errorMessage);
                  }
                } else {
                  // Success
                  String successMessage = result['message'] ?? 'Kendaraan berhasil masuk parkir';
                  _showSuccessDialog('✅ $successMessage');
                }
              } else {
                _showErrorDialog('❌ Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fiber_manual_record,
              size: 8, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Parkir'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: MobileScannerController(),
                  onDetect: _onDetect,
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Memproses...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Arahkan kamera ke QR Code kendaraan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                if (scannedCode != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Terdeteksi: ${scannedCode!}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}