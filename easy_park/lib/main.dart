import 'package:flutter/material.dart';
import 'views/user/login_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'views/user/register_screen.dart';
import 'SplashScreen.dart';
import 'widgets/Drawer_Navigation.dart';
import 'package:easy_park/services/local_db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
  await LocalDbService.init();
  final userData = await LocalDbService.getUserData();

  if (userData != null && userData['email'] != null) {
    final role = userData['role'];
    if (role == 'petugas') {
      return const DrawerNavigationwidget();
    } else {
      return const BottomNavigationWidget();
    }
  } else {
    return const LoginScreen();
  }
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Easy Park',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}
