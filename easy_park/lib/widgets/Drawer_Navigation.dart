import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../views/petugas/parkir_mahasiswa.dart';
import '../views/petugas/parkir_tamu.dart';
import '../views/petugas/daftar_mahasiswa.dart';
import '../views/petugas/daftar_tamu.dart';
import 'package:easy_park/views/user/login_screen.dart';
import 'package:easy_park/services/auth_service.dart';

class DrawerNavigationwidget extends StatefulWidget {
  const DrawerNavigationwidget({Key? key}) : super(key: key);

  @override
  _DrawerNavigationwidgetState createState() => _DrawerNavigationwidgetState();
}

class _DrawerNavigationwidgetState extends State<DrawerNavigationwidget> {
  int _selectedIndex = 0;

  // List of pages corresponding to each drawer item
  final List<Widget> _pages = [
    ParkirMahasiswa(),
    ParkirTamu(),
    DaftarMahasiswa(),
    DaftarTamu(),
  ];

  void _onItemTapped(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
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
            onTap: () async {
              Navigator.pop(context); // Close the drawer
              try {
                await AuthService.logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout berhasil'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: EdgeInsets.all(16),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal logout: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: EdgeInsets.all(16),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}