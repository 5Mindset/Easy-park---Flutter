import 'package:flutter/material.dart';
import 'views/user/login_screen.dart';  // Path diperbarui ke lokasi baru 
import 'widgets/bottom_navigation.dart'; // Adjust the import path if needed
import 'views/user/register_screen.dart';
import 'SplashScreen.dart';
import 'widgets/Drawer_Navigation.dart';

void main() {
  runApp(const MyApp());
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
      // Langsung mengarah ke BottomNavigation
      home: const BottomNavigationWidget(), // Ganti ke widget BottomNavigation Anda
    );
  }
}
