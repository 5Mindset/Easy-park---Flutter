
import 'package:flutter/material.dart';

class Histori extends StatelessWidget {
  const Histori({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Histori',
          style: TextStyle(
            color: Color(0xFF1D1540),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF1D1540)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateSection('06 Januari 2024'),
          _buildHistoryCard('Honda Beat', '19.00', 'Masuk', 'P0210', true),
          _buildHistoryCard('Honda Beat', '19.00', 'Keluar', 'P0210', false),
          const SizedBox(height: 20),
          _buildDateSection('08 Januari 2024'),
          _buildHistoryCard('Honda Beat', '19.00', 'Masuk', 'P0210', true),
          _buildHistoryCard('Honda Beat', '19.00', 'Keluar', 'P0210', false),
        ],
      ),
    );
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

  Widget _buildHistoryCard(String vehicle, String time, String status, String plate, bool isMasuk) {
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
                  vehicle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(time),
                    const Text(' . '),
                    Text(
                      status,
                      style: TextStyle(
                        color: isMasuk ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plate,
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
}
