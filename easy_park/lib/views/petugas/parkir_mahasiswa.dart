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
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    final String? code = barcodes.isNotEmpty ? barcodes.first.rawValue : null;

    if (code != null && code != scannedCode) {
      setState(() {
        scannedCode = code;
        _isProcessing = true;
      });

      print('Scan Results: $code');

      final uri = Uri.tryParse(code);
      if (uri == null || uri.pathSegments.isEmpty) {
        _showMessage('Format URL tidak valid.', isError: true);
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
          final parkingRecord = data['latest_parking_record'];
          final isParked = parkingRecord != null && parkingRecord['exit_time'] == null;

          // Proses scan parkir (masuk atau keluar otomatis ditentukan server)
          _processParkingScan(
            vehicleId: int.parse(id),
            type: data['model']?['vehicle_type']?['name'] ?? '-',
            brand: data['model']?['vehicle_brand']?['name'] ?? '-',
            plate: data['plate_number'] ?? '-', 
            model: data['model']?['name'] ?? '-',
            currentlyParked: isParked,
          );
        } else {
          _showMessage('Gagal mengambil data kendaraan. Status: ${response.statusCode}', isError: true);
          _resetProcessing();
        }
      } catch (e) {
        _showMessage('Terjadi kesalahan: $e', isError: true);
        _resetProcessing();
      }
    }
  }

  void _processParkingScan({
    required int vehicleId,
    required String type,
    required String brand,
    required String plate,
    required String model,
    required bool currentlyParked,
  }) async {
    // Show brief vehicle info
    String action = currentlyParked ? 'Keluar' : 'Masuk';
    _showMessage('$action: $type $brand - $plate', duration: 2);
    
    // Process after showing info
    await Future.delayed(const Duration(seconds: 1));

    
    final result = await ParkingService().scanParkirKendaraan(vehicleId: vehicleId);

    if (result != null) {
      print('Parking scan result: $result'); // Debug log
      
      if (result['success'] == false) {
        String errorMessage = result['message'] ?? 'Terjadi kesalahan';
        if (result['status_code'] == 409) {
          _showMessage('⚠️ Area parkir penuh!', isError: true);
        } else {
          _showMessage('❌ $errorMessage', isError: true);
        }
      } else {
        // Periksa response dari server untuk menentukan aksi yang dilakukan
        String successMessage = _determineSuccessMessage(result, currentlyParked);
        _showMessage(successMessage, isError: false);
      }
    } else {
      _showMessage('❌ Koneksi server bermasalah', isError: true);
    }
    
    _resetProcessing();
  }

  String _determineSuccessMessage(Map<String, dynamic> result, bool wasParked) {
    // Prioritas 1: Cek message dari server jika ada
    if (result.containsKey('message') && result['message'] != null) {
      String serverMessage = result['message'].toString().toLowerCase();
      if (serverMessage.contains('masuk') || serverMessage.contains('entry') || serverMessage.contains('enter')) {
        return '✅ Masuk parkir berhasil';
      } else if (serverMessage.contains('keluar') || serverMessage.contains('exit') || serverMessage.contains('out')) {
        return '✅ Keluar parkir berhasil';
      }
    }
    
    // Prioritas 2: Cek data parking_record dari response
    if (result.containsKey('data')) {
      var data = result['data'];
      if (data != null && data.containsKey('parking_record')) {
        var parkingRecord = data['parking_record'];
        if (parkingRecord != null) {
          // Jika ada exit_time, berarti keluar parkir
          if (parkingRecord.containsKey('exit_time') && parkingRecord['exit_time'] != null) {
            return '✅ Keluar parkir berhasil';
          }
          // Jika ada entry_time tapi tidak ada exit_time, berarti masuk parkir
          else if (parkingRecord.containsKey('entry_time') && parkingRecord['entry_time'] != null) {
            return '✅ Masuk parkir berhasil';
          }
        }
      }
    }
    
    // Prioritas 3: Berdasarkan status sebelumnya (fallback)
    if (wasParked) {
      return '✅ Keluar parkir berhasil';
    } else {
      return '✅ Masuk parkir berhasil';
    }
  }

  void _showMessage(String message, {bool isError = false, int duration = 2}) {
    // Show message in overlay instead of dialog
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.15,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade600 : Colors.green.shade600,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(Duration(seconds: duration), () {
      overlayEntry?.remove();
      _resetForNextScan();
    });
  }

  void _resetProcessing() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  void _resetForNextScan() {
    if (mounted) {
      setState(() {
        scannedCode = null;
        _isProcessing = false;
      });
    }
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
                  controller: MobileScannerController(
                    detectionSpeed: DetectionSpeed.noDuplicates,
                    detectionTimeoutMs: 1000,
                  ),
                  onDetect: _onDetect,
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black26,
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