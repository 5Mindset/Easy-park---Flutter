import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'views/user/login_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'views/user/register_screen.dart';
import 'SplashScreen.dart';
import 'widgets/Drawer_Navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi hanya jika di desktop
  if (!isMobile()) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

// Helper function untuk deteksi platform
bool isMobile() {
  return identical(0, 0.0);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
