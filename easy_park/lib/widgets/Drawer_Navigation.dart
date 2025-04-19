import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../views/petugas/parkir_mahasiswa.dart';
import '../views/petugas/parkir_tamu.dart';
import '../views/petugas/daftar_mahasiswa.dart';
import '../views/petugas/daftar_tamu.dart';

class DrawerNavigationwidget extends StatefulWidget {
  const DrawerNavigationwidget({Key? key}) : super(key: key);

  @override
  _DrawerNavigationwidgetState createState() => _DrawerNavigationwidgetState();
}

class _DrawerNavigationwidgetState extends State<DrawerNavigationwidget> {
  int _selectedIndex = 0;

  // List of pages corresponding to each drawer item
  final List<Widget> _pages = [
    const ParkirMahasiswa(),
    const ParkirTamu(),
    const DaftarMahasiswa(),
    const DaftarTamu(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking App'),
      ),
      drawer: CustomDrawer(
        onItemTapped: _onItemTapped,
        selectedIndex: _selectedIndex,
      ),
      body: _pages[_selectedIndex], // Display the selected page
    );
  }
}

class CustomDrawer extends StatelessWidget {
  final Function(int) onItemTapped;
  final int selectedIndex;

  const CustomDrawer({
    Key? key,
    required this.onItemTapped,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E), // Dark blue color
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: SvgPicture.asset(
                    'assets/profile.svg',
                    width: 30,
                    height: 30,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pak Satpam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  '4567465745899',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: SvgPicture.asset(
              'assets/student.svg',
              width: 24,
              height: 24,
            ),
            title: const Text('Parkir (mahasiswa)'),
            tileColor: selectedIndex == 0 ? Colors.grey[200] : null,
            onTap: () {
              onItemTapped(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: SvgPicture.asset(
              'assets/guest.svg',
              width: 24,
              height: 24,
            ),
            title: const Text('Parkir (tamu)'),
            tileColor: selectedIndex == 1 ? Colors.grey[200] : null,
            onTap: () {
              onItemTapped(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: SvgPicture.asset(
              'assets/history.svg',
              width: 24,
              height: 24,
            ),
            title: const Text('Daftar (mahasiswa)'),
            tileColor: selectedIndex == 2 ? Colors.grey[200] : null,
            onTap: () {
              onItemTapped(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: SvgPicture.asset(
              'assets/list.svg',
              width: 24,
              height: 24,
            ),
            title: const Text('Daftar (tamu)'),
            tileColor: selectedIndex == 3 ? Colors.grey[200] : null,
            onTap: () {
              onItemTapped(3);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: SvgPicture.asset(
              'assets/logout.svg',
              width: 24,
              height: 24,
            ),
            title: const Text('Log out'),
            onTap: () {
              Navigator.pop(context);
              // Implement logout functionality
            },
          ),
        ],
      ),
    );
  }
}