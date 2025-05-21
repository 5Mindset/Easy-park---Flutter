import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/local_db_service.dart';

class DaftarMahasiswa extends StatefulWidget {
  const DaftarMahasiswa({Key? key}) : super(key: key);

  @override
  _DaftarMahasiswaState createState() => _DaftarMahasiswaState();
}

class _DaftarMahasiswaState extends State<DaftarMahasiswa> {
  bool isLoading = true;
  String? _token;
  List<ParkirAktif> parkirList = [];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    try {
      final savedLogin = await LocalDbService.getLogin();
      final token = savedLogin?['token'];

      if (token != null) {
        setState(() {
          _token = token;
        });
        await fetchParkirList(token);
      } else {
        debugPrint('Token tidak ditemukan. Pengguna belum login.');
      }
    } catch (e) {
      debugPrint('Gagal mengambil token: $e');
    }
  }

  Future<void> fetchParkirList(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/parking-records/active'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          parkirList = data.map((item) => ParkirAktif.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        debugPrint('Gagal memuat data parkir: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error mengambil data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Kendaraan Sedang Parkir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.local_parking, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : parkirList.isEmpty
                        ? const Center(child: Text('Tidak ada kendaraan yang sedang parkir.'))
                        : ListView.builder(
                            itemCount: parkirList.length,
                            itemBuilder: (context, index) {
                              return ParkirAktifCard(parkir: parkirList[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParkirAktif {
  final String plateNumber;
  final String ownerName;
  final String entryTime;
  final String status;

  ParkirAktif({
    required this.plateNumber,
    required this.ownerName,
    required this.entryTime,
    required this.status,
  });

  factory ParkirAktif.fromJson(Map<String, dynamic> json) {
    return ParkirAktif(
      plateNumber: json['plate_number'] ?? '-',
      ownerName: json['owner_name'] ?? '-',
      entryTime: json['entry_time'] ?? '-',
      status: json['status'] ?? '-',
    );
  }
}

class ParkirAktifCard extends StatelessWidget {
  final ParkirAktif parkir;

  const ParkirAktifCard({Key? key, required this.parkir}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.indigo, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parkir.plateNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Pemilik: ${parkir.ownerName}'),
                const SizedBox(height: 4),
                Text('Masuk: ${parkir.entryTime}'),
                const SizedBox(height: 4),
                Text('Status: ${parkir.status}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
