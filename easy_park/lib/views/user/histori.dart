import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/local_db_service.dart';

class ParkingRecord {
  final String vehicle;
  final String time;
  final String status;
  final String plate;
  final DateTime dateTime; // Tambahkan untuk sorting

  ParkingRecord({
    required this.vehicle,
    required this.time,
    required this.status,
    required this.plate,
    required this.dateTime,
  });

  // Factory untuk record masuk
  factory ParkingRecord.fromRawJsonEntry(Map<String, dynamic> json) {
    String rawTime = json['entry_time'] ?? '';
    String formattedTime = '';
    DateTime dateTime = DateTime.now();

    if (rawTime.isNotEmpty) {
      try {
        dateTime = DateTime.parse(rawTime);
        formattedTime = DateFormat.Hm('id_ID').format(dateTime);
      } catch (e) {
        formattedTime = '';
      }
    }

    return ParkingRecord(
      vehicle: json['vehicle_type_name'] ?? '',
      time: formattedTime,
      status: 'Masuk',
      plate: json['plate_number'] ?? '',
      dateTime: dateTime,
    );
  }

  // Factory untuk record keluar
  factory ParkingRecord.fromRawJsonExit(Map<String, dynamic> json) {
    String rawTime = json['exit_time'] ?? '';
    String formattedTime = '';
    DateTime dateTime = DateTime.now();

    if (rawTime.isNotEmpty) {
      try {
        dateTime = DateTime.parse(rawTime);
        formattedTime = DateFormat.Hm('id_ID').format(dateTime);
      } catch (e) {
        formattedTime = '';
      }
    }

    return ParkingRecord(
      vehicle: json['vehicle_type_name'] ?? '',
      time: formattedTime,
      status: 'Keluar',
      plate: json['plate_number'] ?? '',
      dateTime: dateTime,
    );
  }
}

class ParkingHistorySection {
  final DateTime date;
  final List<ParkingRecord> records;

  ParkingHistorySection({
    required this.date,
    required this.records,
  });

  String get formattedDate => DateFormat('d MMM', 'id_ID').format(date);
}

class Histori extends StatefulWidget {
  const Histori({Key? key}) : super(key: key);

  @override
  _HistoriState createState() => _HistoriState();
}

class _HistoriState extends State<Histori> {
  bool isLoading = true;
  String? _token;
  List<ParkingHistorySection> historyList = [];
  String? errorMessage;
  DateTime? _selectedDate;

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
        await fetchParkingHistory(token);
      } else {
        setState(() {
          errorMessage = 'Token tidak ditemukan';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal mengambil token: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchParkingHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/parking-records/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Map dengan DateTime key
        Map<DateTime, List<ParkingRecord>> grouped = {};
        
        // List untuk menampung semua record
        List<ParkingRecord> allRecords = [];

        for (var item in data) {
          // Buat record untuk entry jika ada entry_time
          if (item['entry_time'] != null && item['entry_time'].toString().isNotEmpty) {
            try {
              ParkingRecord entryRecord = ParkingRecord.fromRawJsonEntry(item);
              allRecords.add(entryRecord);
            } catch (e) {
              print('Error parsing entry record: $e');
            }
          }

          // Buat record untuk exit jika ada exit_time
          if (item['exit_time'] != null && item['exit_time'].toString().isNotEmpty) {
            try {
              ParkingRecord exitRecord = ParkingRecord.fromRawJsonExit(item);
              allRecords.add(exitRecord);
            } catch (e) {
              print('Error parsing exit record: $e');
            }
          }
        }

        // Group by date
        for (var record in allRecords) {
          DateTime dateOnly = DateTime(record.dateTime.year, record.dateTime.month, record.dateTime.day);
          
          if (!grouped.containsKey(dateOnly)) {
            grouped[dateOnly] = [];
          }
          grouped[dateOnly]!.add(record);
        }

        // Sort records dalam setiap section berdasarkan waktu (descending)
        grouped.forEach((date, records) {
          records.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        });

        // Ubah map menjadi list of ParkingHistorySection
        List<ParkingHistorySection> sections = grouped.entries.map((entry) {
          return ParkingHistorySection(date: entry.key, records: entry.value);
        }).toList();

        // Urutkan sections dari tanggal terbaru ke terlama
        sections.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          historyList = sections;
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal mengambil data. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error saat mengambil data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildDateSection(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        DateFormat('d MMM', 'id_ID').format(date),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ParkingRecord record) {
    bool isMasuk = record.status.toLowerCase() == 'masuk';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isMasuk ? Colors.greenAccent : Colors.redAccent,
            child: Icon(
              isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.vehicle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(record.time),
                    const Text(' · '),
                    Text(
                      record.status,
                      style: TextStyle(
                        color: isMasuk ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  record.plate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _selectedDate == null
        ? historyList
        : historyList.where((section) {
            final sectionDate = section.date;
            final selectedDateOnly = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
            return sectionDate.year == selectedDateOnly.year &&
                sectionDate.month == selectedDateOnly.month &&
                sectionDate.day == selectedDateOnly.day;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1D1540),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadTokenAndFetchData(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _selectedDate == null
                                ? 'Pilih Tanggal'
                                : DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate!),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF1D1540),
                          ),
                        ),
                        if (_selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredHistory.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'Tidak ada data history',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filteredHistory.map((section) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateSection(section.date),
                            ...section.records.map(_buildHistoryCard).toList(),
                          ],
                        );
                      }).toList(),
                  ],
                ),
    );
  }
}