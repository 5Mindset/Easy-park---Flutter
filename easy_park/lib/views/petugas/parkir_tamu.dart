import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/local_db_service.dart';

class ParkirTamu extends StatefulWidget {
  const ParkirTamu({Key? key}) : super(key: key);

  @override
  State<ParkirTamu> createState() => _ParkirTamuState();
}

class _ParkirTamuState extends State<ParkirTamu> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _platController = TextEditingController();
  int? _selectedTypeId;
  List<dynamic> _vehicleTypes = [];
  String? _token;
  bool _isLoadingTypes = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    final savedLogin = await LocalDbService.getLogin();
    final token = savedLogin?['token'];
    if (token != null) {
      setState(() {
        _token = token;
      });
      await _fetchVehicleTypes(token);
    }
  }

  Future<void> _fetchVehicleTypes(String token) async {
    setState(() {
      _isLoadingTypes = true;
    });
    
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/vehicle-types'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _vehicleTypes = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Gagal mengambil tipe kendaraan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat tipe kendaraan: $e')),
      );
    } finally {
      setState(() {
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_namaController.text.isEmpty ||
        _platController.text.isEmpty ||
        _selectedTypeId == null ||
        _token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data terlebih dahulu')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Menyimpan data...'),
          ],
        ),
      ),
    );

    try {
      final body = {
        'name': _namaController.text,
        'plate_number': _platController.text,
        'vehicle_type_id': _selectedTypeId,
        'status': 'parked',
        // Area parkir akan menggunakan default dari backend
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/guest-vehicles'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sukses'),
            content: const Text(
                'Data tamu telah ditambahkan.\nSilakan cek daftar tamu.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  _clearForm();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${error['message'] ?? response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _namaController.clear();
    _platController.clear();
    setState(() {
      _selectedTypeId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Kendaraan Tamu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nama tamu",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _namaController,
                decoration: InputDecoration(
                  hintText: "contoh: Pak Masud",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Plat Nomor",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _platController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: "contoh: B 1234 ABC",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tipe Kendaraan",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedTypeId,
                items: _vehicleTypes.map<DropdownMenuItem<int>>((type) {
                  final areaSize = double.parse(type['area_size'].toString());
                  return DropdownMenuItem<int>(
                    value: type['id'],
                    child: Text('${type['name']} (${areaSize.toStringAsFixed(1)} m²)'),
                  );
                }).toList(),
                onChanged: _isLoadingTypes ? null : (value) {
                  setState(() {
                    _selectedTypeId = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: _isLoadingTypes ? 'Memuat...' : 'Pilih tipe kendaraan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingTypes ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF130160),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "KONFIRMASI",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _platController.dispose();
    super.dispose();
  }
}