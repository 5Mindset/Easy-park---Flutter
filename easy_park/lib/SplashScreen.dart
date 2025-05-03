import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_park/views/user/login_screen.dart';
import 'package:easy_park/services/auth_service.dart';
import 'package:easy_park/widgets/Bottom_Navigation.dart';
import 'package:easy_park/widgets/Drawer_Navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final result = await AuthService.autoLogin();
    debugPrint('Auto-login result: $result');

    await Future.delayed(const Duration(seconds: 2)); // Biar splash kelihatan

    if (!mounted) return;

    if (result['success'] == true) {
      final redirectTo = result['redirect_to'];
      final role = result['role'];
      debugPrint('Redirect to: $redirectTo, Role: $role');

      Widget targetPage;
      if (redirectTo == 'Bottom_Navigation' || role == 'mahasiswa') {
        targetPage = const BottomNavigationWidget(); // Mahasiswa
      } else if (redirectTo == 'petugasHome' || role == 'petugas') {
        targetPage = const DrawerNavigationwidget(); // Petugas
      } else if (redirectTo == 'adminHome' || role == 'admin') {
        targetPage = const LoginScreen(); // Admin not supported in mobile
      } else {
        targetPage = const LoginScreen(); // Fallback
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162A5D), // 🔵 latar belakang biru gelap
      body: Center(
        child: SvgPicture.asset(
          'assets/splash.svg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}