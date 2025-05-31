import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/local_db_service.dart';

class DaftarTamu extends StatefulWidget {
  const DaftarTamu({Key? key}) : super(key: key);

  @override
  State<DaftarTamu> createState() => _DaftarTamuState();
}

class _DaftarTamuState extends State<DaftarTamu> {
  String? _token;
  List<Tamu> tamuList = [];
  List<Tamu> filteredList = [];
  bool isLoading = true;
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
        await fetchTamuList(token);
      } else {
        debugPrint('Token tidak ditemukan. Pengguna belum login.');
      }
    } catch (e) {
      debugPrint('Gagal mengambil token: $e');
    }
  }

  Future<void> fetchTamuList(String token) async {
    try {
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
        final all = data
            .where((item) => item['status'] == 'parked')
            .map<Tamu>((json) => Tamu.fromJson(json))
            .toList();

        // Sort by entry time in descending order (newest first)
        all.sort((a, b) => b.entryDateTime.compareTo(a.entryDateTime));

        setState(() {
          tamuList = all;
          filteredList = all;
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data tamu: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error fetching tamu list: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredList = tamuList
          .where((tamu) => 
              tamu.nama.toLowerCase().contains(searchQuery) ||
              tamu.kode.toLowerCase().contains(searchQuery))
          .toList();
      
      // Keep the descending order after filtering
      filteredList.sort((a, b) => b.entryDateTime.compareTo(a.entryDateTime));
    });
  }

  Future<void> exitTamu(Tamu tamu) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin kendaraan dengan plat ${tamu.kode} akan keluar?'),
            const SizedBox(height: 8),
            Text('Nama: ${tamu.nama}', style: const TextStyle(fontSize: 12)),
            Text('Kendaraan: ${tamu.kendaraan}', style: const TextStyle(fontSize: 12)),
            Text('Area: ${tamu.parkingArea}', style: const TextStyle(fontSize: 12)),
            Text('Masuk: ${tamu.waktu}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('BATAL'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('KELUAR'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Memproses...'),
          ],
        ),
      ),
    );

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/guest-vehicles/${tamu.id}/exit'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(responseData['message'] ?? 'Kendaraan berhasil keluar'),
                if (responseData['returned_area'] != null)
                  Text(
                    'Area dikembalikan: ${responseData['returned_area']} m²',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        _loadTokenAndFetchData(); // refresh data
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar: ${error['message'] ?? response.body}'),
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

  Future<void> _refreshData() async {
    if (_token != null) {
      setState(() {
        isLoading = true;
      });
      await fetchTamuList(_token!);
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
                children: [
                  const Expanded(
                    child: Text(
                      'Daftar tamu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: _filterSearch,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau plat nomor...',
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
              if (!isLoading && filteredList.isNotEmpty)
                Text(
                  'Total: ${filteredList.length} kendaraan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.local_parking,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty 
                                    ? 'Tidak ada tamu yang sedang parkir.' 
                                    : 'Tidak ditemukan tamu dengan kata kunci "$searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                            child: ListView.builder(
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                return TamuCard(
                                  tamu: filteredList[index],
                                  onExit: () => exitTamu(filteredList[index]),
                                );
                              },
                            ),
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
  final int id;
  final String nama;
  final String kendaraan;
  final String waktu;
  final String kode;
  final String parkingArea;
  final DateTime entryDateTime;

  Tamu({
    required this.id,
    required this.nama,
    required this.kendaraan,
    required this.waktu,
    required this.kode,
    required this.parkingArea,
    required this.entryDateTime,
  });

  factory Tamu.fromJson(Map<String, dynamic> json) {
    String entryTimeString = json['entry_time'] ?? '';
    DateTime entryDateTime = DateTime.now(); // Default fallback
    
    // Parse the full entry_time for sorting
    try {
      if (entryTimeString.isNotEmpty) {
        entryDateTime = DateTime.parse(entryTimeString);
      }
    } catch (e) {
      debugPrint('Error parsing entry_time: $e');
      // Keep the default DateTime.now() as fallback
    }

    // Extract parking area information
    String parkingAreaName = 'Area Default';
    if (json['parking_area'] != null && json['parking_area']['name'] != null) {
      parkingAreaName = json['parking_area']['name'];
    } else if (json['parking_area_id'] != null) {
      parkingAreaName = 'Area ${json['parking_area_id']}';
    }

    return Tamu(
      id: json['id'],
      nama: json['name'] ?? '',
      kendaraan: json['vehicle_type']?['name'] ?? '-',
      waktu: entryTimeString.isNotEmpty ? entryTimeString.substring(11, 16) : '-',
      kode: json['plate_number'] ?? '',
      parkingArea: parkingAreaName,
      entryDateTime: entryDateTime,
    );
  }
}

class TamuCard extends StatelessWidget {
  final Tamu tamu;
  final VoidCallback onExit;

  const TamuCard({
    Key? key,
    required this.tamu,
    required this.onExit,
  }) : super(key: key);

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
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.indigo,
            child: Icon(Icons.directions_car, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tamu.nama, 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tamu.kendaraan} · ${tamu.waktu}', 
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tamu.kode, 
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tamu.parkingArea,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onExit,
            icon: const Icon(Icons.logout, color: Colors.indigo),
            tooltip: 'Keluar',
          ),
        ],
      ),
    );
  }
}