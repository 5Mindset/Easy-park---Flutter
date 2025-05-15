import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_park/views/user/beranda.dart';
import 'package:easy_park/views/user/kendaraan.dart';
import 'package:easy_park/views/user/qrcode.dart';
import 'package:easy_park/views/user/histori.dart';
import 'package:easy_park/views/user/profile.dart';
import 'package:easy_park/services/selected_vehicle.dart';

class BottomNavigationWidget extends StatefulWidget {
  final int initialTab;

  const BottomNavigationWidget({Key? key, this.initialTab = 0})
      : super(key: key);

  @override
  _BottomNavigationWidgetState createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  late int _selectedIndex;

  late Future<void> _loadFuture;

  Widget _buildQRCodePage() {
  return FutureBuilder(
    future: _loadFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      return const QRCode(); // ✅ tanpa parameter
    },
  );
}


  final List<Widget> _pages = [
    const Beranda(),
    const KendaraanScreen(),
    const Placeholder(), // Will be replaced by _buildQRCodePage dynamically
    const Histori(),
    const Profile(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _loadFuture = SelectedVehicle().loadSelectedVehicle();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMiddleTabItem() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: IconButton(
        icon: SvgPicture.asset(
          'assets/qrcode.svg',
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        onPressed: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 2 ? _buildQRCodePage() : _pages[_selectedIndex],
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: Colors.white,
            elevation: 10,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: _buildNavItem(0, 'assets/beranda.svg', 'Beranda')),
                  Expanded(
                      child: _buildNavItem(
                          1, 'assets/kendaraan.svg', 'Kendaraan')),
                  const SizedBox(width: 56),
                  Expanded(
                      child: _buildNavItem(3, 'assets/histori.svg', 'Histori')),
                  Expanded(
                      child: _buildNavItem(4, 'assets/profile.svg', 'Profile')),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 25,
            child: _buildMiddleTabItem(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 27,
            height: 27,
            colorFilter: ColorFilter.mode(
              isSelected ? Colors.black : Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.black : Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
