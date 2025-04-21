import 'package:flutter/material.dart';

class MahasiswaHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mahasiswa Home'),
      ),
      body: Center(
        child: Text('Selamat datang di halaman Mahasiswa!'),
      ),
    );
  }
}
