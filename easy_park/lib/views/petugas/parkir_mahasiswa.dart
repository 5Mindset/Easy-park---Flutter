import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ParkirMahasiswa extends StatefulWidget {
  const ParkirMahasiswa({Key? key}) : super(key: key);

  @override
  State<ParkirMahasiswa> createState() => _ParkirMahasiswaState();
}

class _ParkirMahasiswaState extends State<ParkirMahasiswa> {
  String? scannedCode;

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    final String? code = barcodes.isNotEmpty ? barcodes.first.rawValue : null;

    if (code != null && code != scannedCode) {
      setState(() {
        scannedCode = code;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR Code: $code')),
      );

      // TODO: Arahkan ke halaman berikutnya jika perlu
      // Navigator.push(...);
    }
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
