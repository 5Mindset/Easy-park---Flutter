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

  ParkingRecord({
    required this.vehicle,
    required this.time,
    required this.status,
    required this.plate,
  });

  factory ParkingRecord.fromRawJson(Map<String, dynamic> json) {
    String rawStatus = (json['status'] ?? '').toString().toLowerCase();
    String displayStatus = '';
    String rawTime = '';

    if (rawStatus == 'parked') {
      displayStatus = 'Masuk';
      rawTime = json['entry_time'] ?? '';
    } else if (rawStatus == 'exited') {
      displayStatus = 'Keluar';
      rawTime = json['exit_time'] ?? '';
    } else {
      displayStatus = json['status'] ?? '';
      rawTime = json['entry_time'] ?? '';
    }

    String formattedTime = '';
    if (rawTime.isNotEmpty) {
      try {
        final parsedTime = DateTime.parse(rawTime);
        formattedTime = DateFormat.Hm('id_ID').format(parsedTime);
      } catch (e) {
        formattedTime = '';
      }
    }

    return ParkingRecord(
      vehicle: json['vehicle_type_name'] ?? '',
      time: formattedTime,
      status: displayStatus,
      plate: json['plate_number'] ?? '',
    );
  }
}

class ParkingHistorySection {
  final String date;
  final List<ParkingRecord> records;

  ParkingHistorySection({
    required this.date,
    required this.records,
  });
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

        Map<String, List<ParkingRecord>> grouped = {};

        for (var item in data) {
          String rawTime = item['entry_time'] ?? item['exit_time'] ?? '';
          if (rawTime.isEmpty) continue;

          DateTime parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
          String formattedDate = DateFormat('d MMM', 'id_ID').format(parsedTime);

          ParkingRecord record = ParkingRecord.fromRawJson(item);

          if (!grouped.containsKey(formattedDate)) {
            grouped[formattedDate] = [];
          }
          grouped[formattedDate]!.add(record);
        }

        List<ParkingHistorySection> sections = grouped.entries.map((entry) {
          return ParkingHistorySection(date: entry.key, records: entry.value);
        }).toList();

        sections.sort((a, b) {
          final dateA = DateFormat('d MMM', 'id_ID').parse(a.date);
          final dateB = DateFormat('d MMM', 'id_ID').parse(b.date);
          return dateB.compareTo(dateA);
        });

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

  Widget _buildDateSection(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        date,
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
            final sectionDate = DateFormat('d MMM', 'id_ID').parse(section.date);
            return sectionDate.day == _selectedDate!.day &&
                sectionDate.month == _selectedDate!.month &&
                sectionDate.year == _selectedDate!.year;
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
              ? Center(child: Text(errorMessage!))
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
