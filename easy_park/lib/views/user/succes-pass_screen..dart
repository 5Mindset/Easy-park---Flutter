import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SuccessScreen(),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80), // Jarak dari atas
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Sukses',
                    style: TextStyle(
                      color: Color(0xFF1E0E4F),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Kembali ke halaman login dan jangan lupa password\nkamu lagi ya',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30), // Jarak sebelum gambar
                  SvgPicture.asset(
                    'assets/otp.svg',
                    width: 200,
                    height: 200,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Ruang sebelum tombol
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E17EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'KEMBALI KE HALAMAN MASUK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            // Mengganti Align dengan Container untuk kontrol penuh
            Container(
              width: double.infinity, // Memastikan lebar penuh
              height: screenHeight * 0.25, // Tinggi tetap 25% dari layar
              child: IgnorePointer(
                child: SvgPicture.asset(
                  'assets/mask.svg',
                  width: double.infinity, // Pastikan lebar penuh
                  height: screenHeight * 0.25, // Sesuaikan dengan container
                  fit: BoxFit.fill, // Mengisi seluruh area tanpa celah
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
