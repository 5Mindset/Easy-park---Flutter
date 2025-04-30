import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Beranda extends StatelessWidget {
  const Beranda({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView( // Wrap the entire content in SingleChildScrollView
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting and logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
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
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 0),

                // Status card
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
                        children: const [
                          Text(
                            'Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Terparkir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 35),
                          Text(
                            '13/03/2025',
                            style: TextStyle(
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

                // Features section
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
                        title: 'Scan\nKode QR',
                        color: const Color(0xFFB3E5FC),
                        icon: 'assets/qrcode2.svg',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: FeatureButton(
                        title: 'Kontak',
                        color: const Color(0xFFD1C4E9),
                        icon: 'assets/call.svg',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: FeatureButton(
                        title: 'Panduan',
                        color: const Color(0xFFFFE0B2),
                        icon: 'assets/guide.svg',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // History section
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
                  child: Column( // Replace ListView with Column
                    children: const [
                      HistoryItem(
                        vehicle: 'beat',
                        hour: 'E41232280',
                        action: 'Masuk',
                        location: 'P0210',
                        avatarText: 'B',
                        avatarColor: Color(0xFF8BC34A),
                      ),
                      HistoryItem(
                        vehicle: 'Andi',
                        hour: '20.00',
                        action: 'Keluar',
                        location: 'P0211',
                        avatarText: 'A',
                        avatarColor: Color(0xFF8BC34A),
                      ),
                      HistoryItem(
                        vehicle: 'Sinta',
                        hour: '19.00',
                        action: 'Masuk',
                        location: 'P0212',
                        avatarText: 'S',
                        avatarColor: Color(0xFF8BC34A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // Add some padding at the bottom
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
    Key? key,
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 32,
              height: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
    Key? key,
    required this.vehicle,
    required this.hour,
    required this.action,
    required this.location,
    required this.avatarText,
    required this.avatarColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define color based on action
    Color actionColor = action == 'Masuk'
        ? const Color(0xFF4CAF50) // Green for 'Masuk'
        : const Color(0xFFE53935); // Red for 'Keluar'

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF0F0F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor,
            ),
            child: Center(
              child: Text(
                avatarText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Text(
                    hour,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    action,
                    style: TextStyle(
                      fontSize: 12,
                      color: actionColor,
                    ),
                  ),
                ],
              ),
              Text(
                location,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1A3A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}