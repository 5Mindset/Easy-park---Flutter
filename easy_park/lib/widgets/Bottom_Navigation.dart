import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../views/user/beranda.dart';
import '../views/user/kendaraan.dart';
import '../views/user/qrcode.dart';
import '../views/user/histori.dart';
import '../views/user/profile.dart';

void main() {
  runApp(const BottomNavigationWidget());
}

class BottomNavigationWidget extends StatefulWidget {
  const BottomNavigationWidget({Key? key}) : super(key: key);

  @override
  _BottomNavigationWidgetState createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Beranda(),
     Kendaraan(),
    const QRCode(),
    const Histori(),
    const Profile(),
  ];

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
      body: _pages[_selectedIndex],
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
                  Expanded(child: _buildNavItem(0, 'assets/beranda.svg', 'Beranda')),
                  Expanded(child: _buildNavItem(1, 'assets/kendaraan.svg', 'Kendaraan')),
                  const SizedBox(width: 56),
                  Expanded(child: _buildNavItem(3, 'assets/histori.svg', 'Histori')),
                  Expanded(child: _buildNavItem(4, 'assets/profile.svg', 'Profile')),
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