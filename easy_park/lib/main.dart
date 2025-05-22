import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Tambahkan ini
import 'views/user/login_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'views/user/register_screen.dart';
import 'SplashScreen.dart';
import 'widgets/Drawer_Navigation.dart';
import 'package:easy_park/services/local_db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService.init(); // Initialize database here
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Easy Park',
      // ▼ Tambahkan konfigurasi lokalasi di sini ▼
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // Untuk Material Design L10n
        GlobalWidgetsLocalizations.delegate,  // Untuk text direction (RTL/LTR)
        GlobalCupertinoLocalizations.delegate, // Untuk iOS-style L10n
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Bahasa Indonesia
      ],
      locale: const Locale('id', 'ID'), // Set default ke Indonesia
      // ▼ Lanjutkan dengan tema dan halaman awal ▼
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(), // Start with SplashScreen
    );
  }
}