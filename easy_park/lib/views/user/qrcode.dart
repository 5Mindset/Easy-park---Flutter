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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer for lifecycle changes
    _loadSelectedVehicle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload data when the app/screen is resumed
      _loadSelectedVehicle();
    }
  }

  Future<void> _loadSelectedVehicle() async {
    await selectedVehicle.loadSelectedVehicle();
    print('Loaded vehicle: ${selectedVehicle.vehicle}'); // Debug print
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up observer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
      ),
      body: Center(
        child: qrCodeUrl.isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    vehicleName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plateNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SvgPicture.network(
                    qrCodeUrl,
                    width: 200,
                    height: 200,
                    placeholderBuilder: (context) =>
                        const CircularProgressIndicator(),
                  ),
                ],
              )
            : const Text('No QR Code Available'),
      ),
    );
  }
}                           