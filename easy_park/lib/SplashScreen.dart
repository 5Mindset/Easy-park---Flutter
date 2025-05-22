import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_park/views/user/login_screen.dart';
import 'package:easy_park/services/auth_service.dart';
import 'package:easy_park/services/local_db_service.dart';
import 'package:easy_park/widgets/bottom_navigation.dart';
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Show splash screen for minimum 2 seconds
      final stopwatch = Stopwatch()..start();

      // Check login status
      final result = await _checkLoginStatus();

      // Ensure splash screen shows for at least 2 seconds
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 2000) {
        await Future.delayed(Duration(milliseconds: 2000 - elapsed));
      }

      if (!mounted) return;

      // Navigate to appropriate screen
      _navigateToScreen(result);
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  Future<Map<String, dynamic>> _checkLoginStatus() async {
    try {
      // First try AuthService auto-login
      final authResult = await AuthService.autoLogin();
      debugPrint('AuthService auto-login result: $authResult');

      if (authResult['success'] == true) {
        return authResult;
      }

      // Fallback: check LocalDbService directly
      final userData = await LocalDbService.getUserData();
      debugPrint('LocalDbService user data: $userData');

      if (userData != null && userData['email'] != null) {
        final role = userData['role'];
        return {
          'success': true,
          'role': role,
          'redirect_to': _getRedirectDestination(role),
        };
      }

      return {'success': false};
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return {'success': false};
    }
  }

  String _getRedirectDestination(String? role) {
    switch (role) {
      case 'mahasiswa':
        return 'Bottom_Navigation';
      case 'petugas':
        return 'petugasHome';
      case 'admin':
        return 'adminHome';
      default:
        return 'login';
    }
  }

  void _navigateToScreen(Map<String, dynamic> result) {
    Widget targetPage;

    if (result['success'] == true) {
      final role = result['role'];
      final redirectTo = result['redirect_to'];

      debugPrint('Navigation - Role: $role, Redirect to: $redirectTo');

      switch (role) {
        case 'mahasiswa':
          targetPage = const BottomNavigationWidget();
          break;
        case 'petugas':
          targetPage = const DrawerNavigationwidget();
          break;
        case 'admin':
          // Admin not supported in mobile, redirect to login
          targetPage = const LoginScreen();
          break;
        default:
          targetPage = const LoginScreen();
      }
    } else {
      targetPage = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162A5D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SVG Logo
            Expanded(
              child: Center(
                child: SvgPicture.asset(
                  'assets/splash.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            // Loading indicator
            const Padding(
              padding: EdgeInsets.only(bottom: 50.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
