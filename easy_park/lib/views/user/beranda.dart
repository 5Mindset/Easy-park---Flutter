import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/local_db_service.dart';
import 'package:easy_park/views/user/PanduanPage.dart'; // pastikan file ini ada

class Beranda extends StatefulWidget {
  const Beranda({Key? key}) : super(key: key);

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  String? _token;
  bool isLoading = true;

  String statusText = '-';
  String statusDate = '-';

  List<HistoryData> historyItems = [];

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
          isLoading = true;
        });

        await fetchLastStatus(token);
        await fetchLastEntryExit(token);
      }
    } catch (e) {
      debugPrint('Gagal mengambil token: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchLastStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/parking-records/last-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String statusApi = (data['status'] ?? '').toString().toLowerCase();

        setState(() {
          statusText = (statusApi == 'parked' || statusApi == 'masuk')
              ? 'Terparkir'
              : (statusApi == 'exited' || statusApi == 'keluar')
                  ? 'Keluar'
                  : '-';
          statusDate = DateFormat('HH:mm').format(DateTime.now());
        });
      } else {
        debugPrint('fetchLastStatus error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetchLastStatus: $e');
    }
  }

  Future<void> fetchLastEntryExit(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/parking-records/last-entry-exit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<HistoryData> tempList = [];

        if (data['last_entry'] != null) {
          final entry = data['last_entry'];
          tempList.add(HistoryData(
            vehicle: entry['plate_number'] ?? '-',
            hour: _formatTime(entry['entry_time']),
            action: entry['status'] ?? '-',
            location: entry['owner_name'] ?? '-',
            avatarText: _getAvatarText(entry['plate_number']),
            avatarColor: const Color(0xFF8BC34A),
          ));
        }

        if (data['last_exit'] != null) {
          final exit = data['last_exit'];
          tempList.add(HistoryData(
            vehicle: exit['plate_number'] ?? '-',
            hour: _formatTime(exit['exit_time']),
            action: exit['status'] ?? '-',
            location: exit['owner_name'] ?? '-',
            avatarText: _getAvatarText(exit['plate_number']),
            avatarColor: const Color(0xFFE53935),
          ));
        }

        setState(() {
          historyItems = tempList;
        });
      } else {
        debugPrint('fetchLastEntryExit error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetchLastEntryExit: $e');
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '-';
    try {
      final fixedStr = timeStr.replaceFirst(' ', 'T');
      final dt = DateTime.parse(fixedStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }

  String _getAvatarText(String? plateNumber) {
    if (plateNumber == null || plateNumber.isEmpty) return '-';
    return plateNumber[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A3A),
                                ),
                              ),
                              Text(
                                'Pengguna',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A3A),
                                ),
                              ),
                            ],
                          ),
                          SvgPicture.asset(
                            'assets/park.svg',
                            width: 120,
                            height: 85,
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),

                      // Status Card
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A3A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  statusText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 35),
                                Text(
                                  statusDate,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 2,
                            child: SvgPicture.asset(
                              'assets/driver.svg',
                              width: 170,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      const Text(
                        'Fitur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A3A),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: FeatureButton(
                              title: 'Kontak',
                              color: const Color(0xFFD1C4E9),
                              icon: 'assets/call.svg',
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Kontak'),
                                    content: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Telepon: 0812-3456-7890'),
                                        SizedBox(height: 8),
                                        Text('Email: support@easypark.com'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Tutup'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FeatureButton(
                              title: 'Panduan',
                              color: const Color(0xFFFFE0B2),
                              icon: 'assets/guide.svg',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PanduanPage()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        'Histori',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A3A),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: historyItems.isEmpty
                              ? const [
                                  Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text('Tidak ada histori parkir'),
                                  ),
                                ]
                              : historyItems.map((item) {
                                  return HistoryItem(
                                    vehicle: item.vehicle,
                                    hour: item.hour,
                                    action: item.action,
                                    location: item.location,
                                    avatarText: item.avatarText,
                                    avatarColor: item.avatarColor,
                                  );
                                }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class FeatureButton extends StatelessWidget {
  final String title;
  final Color color;
  final String icon;
  final VoidCallback onTap;

  const FeatureButton({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(icon, width: 32, height: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1A1A3A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryItem extends StatelessWidget {
  final String vehicle;
  final String hour;
  final String action;
  final String location;
  final String avatarText;
  final Color avatarColor;

  const HistoryItem({
    super.key,
    required this.vehicle,
    required this.hour,
    required this.action,
    required this.location,
    required this.avatarText,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarColor,
        child: Text(
          avatarText,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(vehicle),
      subtitle: Text('$location - $action'),
      trailing: Text(hour),
    );
  }
}

class HistoryData {
  final String vehicle;
  final String hour;
  final String action;
  final String location;
  final String avatarText;
  final Color avatarColor;

  HistoryData({
    required this.vehicle,
    required this.hour,
    required this.action,
    required this.location,
    required this.avatarText,
    required this.avatarColor,
  });
}
