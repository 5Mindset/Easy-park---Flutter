import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
          Uri.parse('http://192.168.1.9:8000/api/vehicles/$id'),
        );

        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          _showVehicleInfoDialog(
            type: data['model']?['vehicle_type']?['name'] ?? '-',
            brand: data['model']?['vehicle_brand']?['name'] ?? '-',
            plate: data['plate_number'] ?? '-',
            model: data['model']?['name'] ?? '-',
          );
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
            onPressed: () {
              // TODO: Lanjutkan proses
              Navigator.of(context).pop();
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
