import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'kendaraan.dart'; // Import VehicleRegistrationScreen
import 'kendaraan_Edit.dart'; // Import KendaraanEdit if needed
import 'package:easy_park/services/vehicle_service.dart';

class KendaraanScreen extends StatefulWidget {
  const KendaraanScreen({Key? key}) : super(key: key);

  @override
  State<KendaraanScreen> createState() => _KendaraanScreenState();
}

class _KendaraanScreenState extends State<KendaraanScreen> {
  List<Map<String, String>> vehicles = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  /// Fetch vehicles from the API using VehicleService
  Future<void> _fetchVehicles() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await VehicleService.getVehicles();
    if (result['success']) {
      final List<dynamic> vehicleData = result['data'];
      setState(() {
        vehicles = vehicleData.map((vehicle) => {
      'name': '${vehicle['model']['name'] ?? ''}',
      'id': '${vehicle['plate_number'] ?? ''}',
      'brand': '${vehicle['model']['vehicle_brand']['name'] ?? ''}',
      'type': '${vehicle['model']['vehicle_type']['name'] ?? ''}',
    }).toList().cast<Map<String, String>>();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        errorMessage = result['message'];
      });
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
                'klik PILIH salah satu kendaraan yang dipakai',
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
                        ? Center(child: Text(errorMessage!))
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
            if (result != null && result is Map<String, String>) {
              setState(() {
                vehicles.add(result);
              });
              // Refresh vehicles from API to ensure sync
              await _fetchVehicles();
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
        return _buildVehicleCard(
          name: vehicle['name'] ?? '',
          id: vehicle['id'] ?? '',
          brand: vehicle['brand'] ?? '',
          type: vehicle['type'] ?? '',
          index: index,
        );
      },
    );
  }

  Widget _buildVehicleCard({
    required String name,
    required String id,
    required String brand,
    required String type,
    required int index,
  }) {
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
                  id,
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
                        onPressed: () {
                          debugPrint('Edit vehicle: $name');
                          // TODO: Navigate to KendaraanEdit
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('EDIT'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Selected: $name ($id)')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('PILIH'),
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
                    content: Text('Apakah Anda yakin ingin menghapus $name?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('BATAL'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // TODO: Call VehicleService.deleteVehicle
                          setState(() {
                            vehicles.removeAt(index);
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kendaraan dihapus')),
                          );
                          // Refresh vehicles from API
                          await _fetchVehicles();
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