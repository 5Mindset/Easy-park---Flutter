import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_park/services/selected_vehicle.dart';

class QRCode extends StatefulWidget {
  const QRCode({Key? key}) : super(key: key);

  @override
  State<QRCode> createState() => _QRCodeState();
}

class _QRCodeState extends State<QRCode> with WidgetsBindingObserver {
  final selectedVehicle = SelectedVehicle();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSelectedVehicle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadSelectedVehicle();
    }
  }

  Future<void> _loadSelectedVehicle() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await selectedVehicle.loadSelectedVehicle();
      print('Loaded vehicle: ${selectedVehicle.vehicle}');
      print('QR Code URL: ${selectedVehicle.qrCodeUrl}'); // Debug QR URL
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading vehicle: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data kendaraan: $e';
      });
    }
  }

 String _buildFullQrCodeUrl(String qrCodeUrl) {
  if (qrCodeUrl.startsWith('http://') || qrCodeUrl.startsWith('https://')) {
    return qrCodeUrl;
  }

  const String baseUrl = 'https://webfw23.myhost.id/gol_bws3';

  // Bersihkan URL dari berbagai prefix yang mungkin ada
  String sanitizedPath = qrCodeUrl;
  
  // Hapus semua kemungkinan prefix /public
  while (sanitizedPath.startsWith('/public/') || sanitizedPath.startsWith('public/')) {
    if (sanitizedPath.startsWith('/public/')) {
      sanitizedPath = sanitizedPath.replaceFirst('/public/', '/');
    } else if (sanitizedPath.startsWith('public/')) {
      sanitizedPath = sanitizedPath.replaceFirst('public/', '');
    }
  }
  
  // Pastikan path dimulai dengan /
  if (!sanitizedPath.startsWith('/')) {
    sanitizedPath = '/$sanitizedPath';
  }
  
  // Gabungkan dengan base URL dan tambahkan /public
  return '$baseUrl/public$sanitizedPath';
}



  Widget _buildQRCodeWidget(String qrCodeUrl) {
    final fullUrl = _buildFullQrCodeUrl(qrCodeUrl);
    print('Full QR URL: $fullUrl'); // Debug full URL

    // Cek apakah file SVG
    if (fullUrl.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        fullUrl,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        // Error handler untuk SVG
        // Note: flutter_svg mungkin tidak memiliki errorBuilder
        // Jadi kita akan wrap dengan fallback
      );
    } else {
      // Untuk file PNG/JPG
      return Image.network(
        fullUrl,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('Image load error: $error');
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 40),
                SizedBox(height: 8),
                Text(
                  'Gagal memuat QR Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data kendaraan...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Code'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSelectedVehicle,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final qrCodeUrl = selectedVehicle.qrCodeUrl ?? '';
    final vehicle = selectedVehicle.vehicle;

    final vehicleName = vehicle != null &&
            vehicle.containsKey('model') &&
            vehicle['model'] != null &&
            vehicle['model'].containsKey('name') &&
            vehicle['model']['name'] != null
        ? vehicle['model']['name']
        : 'Nama tidak tersedia';

    final plateNumber = vehicle != null &&
            vehicle.containsKey('plate_number') &&
            vehicle['plate_number'] != null
        ? vehicle['plate_number']
        : 'Plat tidak tersedia';

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSelectedVehicle,
          ),
        ],
      ),
      body: Center(
        child: qrCodeUrl.isNotEmpty
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              vehicleName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plateNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _buildQRCodeWidget(qrCodeUrl),
                            const SizedBox(height: 16),
                            // Debug info (hapus di production)
                            if (qrCodeUrl.isNotEmpty)
                              Column(
                                children: [
                                  const Divider(),
                                  const Text(
                                    'URL Debug:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    _buildFullQrCodeUrl(qrCodeUrl),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_2,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'QR Code tidak tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Klik tombol PILIH di tab Kendaraan jika Anda sudah memiliki kendaraan',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSelectedVehicle,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}