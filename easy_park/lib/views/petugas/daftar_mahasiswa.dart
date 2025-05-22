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
  List<ParkirAktif> filteredList = [];
  String searchQuery = '';

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

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          parkirList = data.map((item) => ParkirAktif.fromJson(item)).toList();
          filteredList = parkirList;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredList = parkirList.where((item) {
        return item.ownerName.toLowerCase().contains(searchQuery);
      }).toList();
    });
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
              const Text(
                'Daftar mahasiswa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1248),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: _filterSearch,
                decoration: InputDecoration(
                  hintText: 'Cari nama...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredList.isEmpty
                        ? const Center(child: Text('Tidak ada kendaraan yang sedang parkir.'))
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return ParkirAktifCard(parkir: filteredList[index]);
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

  ParkirAktif({
    required this.plateNumber,
    required this.ownerName,
    required this.entryTime,
  });

  factory ParkirAktif.fromJson(Map<String, dynamic> json) {
    return ParkirAktif(
      plateNumber: json['plate_number'] ?? '-',
      ownerName: json['owner_name'] ?? '-',
      entryTime: json['entry_time'] ?? '-',
    );
  }
}

class ParkirAktifCard extends StatelessWidget {
  final ParkirAktif parkir;

  const ParkirAktifCard({Key? key, required this.parkir}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeParts = parkir.entryTime.split(' ');
    final date = timeParts.length > 0 ? timeParts[0] : '-';
    final time = timeParts.length > 1 ? timeParts[1] : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFF1A1248),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parkir.ownerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('$date . $time'),
                const SizedBox(height: 4),
                Text(parkir.plateNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
