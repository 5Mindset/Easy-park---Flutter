import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/local_db_service.dart'; // Pastikan import ini ada

class DaftarTamu extends StatefulWidget {
  const DaftarTamu({Key? key}) : super(key: key);

  @override
  State<DaftarTamu> createState() => _DaftarTamuState();
}

class _DaftarTamuState extends State<DaftarTamu> {
  late Future<List<Tamu>> _futureTamuList;
  String? _token;

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
          _futureTamuList = fetchTamuList(token);
        });
      } else {
        debugPrint('Token tidak ditemukan. Pengguna belum login.');
      }
    } catch (e) {
      debugPrint('Gagal mengambil token: $e');
    }
  }

  Future<List<Tamu>> fetchTamuList(String token) async {
    final response = await http
        .get(
          Uri.parse('$apiBaseUrl/guest-vehicles'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .where((item) => item['status'] == 'parked')
          .map<Tamu>((json) => Tamu.fromJson(json))
          .toList();
    } else {
      throw Exception('Gagal memuat data tamu: ${response.statusCode}');
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar tamu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'TAMBAH',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // List tamu
              Expanded(
                child: _token == null
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder<List<Tamu>>(
                        future: _futureTamuList,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('Tidak ada tamu yang sedang parkir.'));
                          }

                          final tamuList = snapshot.data!;
                          return ListView.builder(
                            itemCount: tamuList.length,
                            itemBuilder: (context, index) {
                              return TamuCard(tamu: tamuList[index]);
                            },
                          );
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

class Tamu {
  final String nama;
  final String kendaraan;
  final String waktu;
  final String kode;

  Tamu({
    required this.nama,
    required this.kendaraan,
    required this.waktu,
    required this.kode,
  });

  factory Tamu.fromJson(Map<String, dynamic> json) {
    return Tamu(
      nama: json['owner_name'] ?? '',
      kendaraan: json['vehicle_model']?['name'] ?? '',
      waktu: json['entry_time']?.substring(11, 16) ?? '-',
      kode: json['plate_number'] ?? '',
    );
  }
}

class TamuCard extends StatelessWidget {
  final Tamu tamu;

  const TamuCard({Key? key, required this.tamu}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.indigo,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tamu.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${tamu.kendaraan} · ${tamu.waktu}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(tamu.kode, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.logout, color: Colors.indigo),
            tooltip: 'Keluar',
          ),
        ],
      ),
    );
  }
}
