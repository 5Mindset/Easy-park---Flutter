// kendaraan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'kendaraan_Add.dart';
import 'package:easy_park/services/vehicle_service.dart';
import 'qrcode.dart';
import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/selected_vehicle.dart';
import 'package:easy_park/widgets/Bottom_Navigation.dart';
import 'kendaraan_Edit.dart';

class KendaraanScreen extends StatefulWidget {
  const KendaraanScreen({Key? key}) : super(key: key);

  @override
  State<KendaraanScreen> createState() => _KendaraanScreenState();
}

class _KendaraanScreenState extends State<KendaraanScreen> {
  List<Map<String, dynamic>> vehicles = [];
  bool isLoading = true;
  String? errorMessage;
  int? selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
    final selected = SelectedVehicle().vehicle;
    if (selected != null) {
      selectedVehicleId = selected['id'];
    }
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await VehicleService.getVehicles();
    if (result['success']) {
      setState(() {
        vehicles = List<Map<String, dynamic>>.from(result['data']);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        errorMessage = result['message'];
        debugPrint(
            'Fetch vehicles failed: ${result['message']} - ${result['error']}');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kendaraan: ${result['message']}')),
      );
    }
  }

  Future<void> _deleteVehicle(int id, String name) async {
  final selected = SelectedVehicle();
  final currentSelected = selected.vehicle;

  // Jika kendaraan yang dihapus adalah yang sedang dipilih, bersihkan dari lokal
  if (currentSelected != null && currentSelected['id'] == id) {
    await selected.clearSelectedVehicle();
    print('Selected vehicle cleared because it was deleted.');
  }

  final result = await VehicleService.deleteVehicle(id);
  if (result['success']) {
    await _fetchVehicles();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kendaraan $name dihapus')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              Text(
                'Klik PILIH salah satu kendaraan yang dipakai',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(
                            child: Text(errorMessage!,
                                textAlign: TextAlign.center))
                        : vehicles.isEmpty
                            ? const Center(child: Text('Tidak ada kendaraan'))
                            : _buildVehicleList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Kendaraan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A4B),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VehicleRegistrationScreen(),
              ),
            );
            await _fetchVehicles();
            if (result != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Kendaraan baru ditambahkan: ${result['plate_number']}')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A4B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text(
            'TAMBAH',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleList() {
  return ListView.builder(
    itemCount: vehicles.length,
    itemBuilder: (context, index) {
      final vehicle = vehicles[index];
      final model = vehicle['model'];
      final brand = model?['vehicle_brand'];
      final type = model?['vehicle_type']; // ← Ubah ini! Bukan dari vehicle_brand
      
      return _buildVehicleCard(
        name: model?['name'] ?? 'Unknown Model',
        id: vehicle['id'].toString(),
        plateNumber: vehicle['plate_number'] ?? 'Unknown Plate',
        brand: brand?['name'] ?? 'Unknown Brand',
        type: type?['name'] ?? 'Unknown Type',
        vehicle: vehicle,
      );
    },
  );
}


  Widget _buildVehicleCard({
    required String name,
    required String id,
    required String plateNumber,
    required String brand,
    required String type,
    required Map<String, dynamic> vehicle,
  }) {
    final qrCodePath = vehicle['qr_code'] ?? '';
    final qrCodeUrl =
        qrCodePath.isNotEmpty ? '$baseUrl/storage/$qrCodePath' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plateNumber,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  brand,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VehicleEditScreen(vehicle: vehicle),
                            ),
                          );
                          await _fetchVehicles(); // Refresh vehicle list
                          if (result != null) {
                            // Check if the updated vehicle is the currently selected one
                            final selectedVehicleInstance = SelectedVehicle();
                            final currentSelectedVehicle =
                                selectedVehicleInstance.vehicle;
                            if (currentSelectedVehicle != null &&
                                currentSelectedVehicle['id'] == result['id']) {
                              // Update SelectedVehicle with the new vehicle data
                              final updatedQrCodePath = result['qr_code'] ?? '';
                              final updatedQrCodeUrl =
                                  updatedQrCodePath.isNotEmpty
                                      ? '$baseUrl/storage/$updatedQrCodePath'
                                      : '';
                              await selectedVehicleInstance.setSelectedVehicle(
                                  updatedQrCodeUrl, result);
                              print(
                                  'Updated SelectedVehicle: $result'); // Debug print
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Kendaraan diperbarui: ${result['plate_number']}')),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black, // Warna teks dan icon
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('EDIT'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: selectedVehicleId == vehicle['id']
                            ? null
                            : () {
                                SelectedVehicle()
                                    .setSelectedVehicle(qrCodeUrl, vehicle);
                                setState(() {
                                  selectedVehicleId = vehicle['id'];
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Selected: $name ($plateNumber)')),
                                );
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BottomNavigationWidget(initialTab: 2),
                                  ),
                                  (route) => false,
                                );
                              },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selectedVehicleId == vehicle['id']
                              ? Colors.green[100]
                              : Colors.white,
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: Text(
                          selectedVehicleId == vehicle['id']
                              ? 'TERPILIH'
                              : 'PILIH',
                          style: TextStyle(
                            color: selectedVehicleId == vehicle['id']
                                ? Colors.green[800]
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: _buildTrashSvg(),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hapus Kendaraan'),
                    content: Text(
                        'Apakah Anda yakin ingin menghapus $name ($plateNumber)?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('BATAL'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteVehicle(int.parse(id), name);
                        },
                        child: const Text('HAPUS'),
                      ),
                    ],
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
              splashRadius: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashSvg() {
    return SvgPicture.asset(
      'assets/trash.svg',
      width: 25,
      height: 25,
      colorFilter: const ColorFilter.mode(
        Colors.red,
        BlendMode.srcIn,
      ),
    );
  }
}
