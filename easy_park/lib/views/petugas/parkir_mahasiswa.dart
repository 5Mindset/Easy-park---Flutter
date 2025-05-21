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

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    final String? code = barcodes.isNotEmpty ? barcodes.first.rawValue : null;

    if (code != null && code != scannedCode) {
      setState(() {
        scannedCode = code;
      });

      // Tampilkan hasil scan di console
      print('Scan Results: $code');

      // Ambil ID dari URL (contoh: http://192.168.1.9:8000/vehicles/22)
      final uri = Uri.tryParse(code);
      if (uri == null || uri.pathSegments.isEmpty) {
        _showErrorDialog('Format URL tidak valid.');
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
              parkingRecordId: parkingRecord['id'],
              plate: data['plate_number'] ?? '-',
            );
          } else {
            _showVehicleInfoDialog(
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmationDialog({
    required int parkingRecordId,
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('KELUAR'),
            onPressed: () async {
              Navigator.of(context).pop(); // Tutup dialog
              final success = await ParkingService().keluarParkirKendaraan(
                parkingRecordId: parkingRecordId,
              );
              if (success) {
                _showSuccessDialog('Kendaraan berhasil keluar parkir.');
              } else {
                _showErrorDialog('Gagal keluar parkir. Coba lagi.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showVehicleInfoDialog({
    required String type,
    required String brand,
    required String plate,
    required String model,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Informasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Tipe', type),
            _buildInfoRow('Brand', brand),
            _buildInfoRow('Plat', plate),
            _buildInfoRow('Model', model),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('TOLAK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('TERIMA'),
            onPressed: () async {
              Navigator.of(context).pop(); // Tutup dialog

              final result = await ParkingService().scanParkirKendaraan(
                vehicleId: int.parse(scannedCode!.split('/').last),
              );

              if (result != null && result['message'] != null) {
                _showSuccessDialog(result['message']);
              } else {
                _showErrorDialog(
                  'Gagal memproses parkir. Periksa koneksi atau coba lagi.',
                );
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
        children: [
          const Icon(Icons.fiber_manual_record,
              size: 10, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(
            '($label)',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Parkir')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: MobileScannerController(),
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                scannedCode != null
                    ? 'Hasil Scan: $scannedCode'
                    : 'Arahkan kamera ke QR Code',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
