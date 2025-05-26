import 'package:flutter/material.dart';

class PanduanPage extends StatelessWidget {
  const PanduanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan'),
        backgroundColor: const Color(0xFF1A1A3A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ExpansionTile(
            title: Text(
              '1. Beranda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              ListTile(title: Text('- Menampilkan status terakhir kendaraan')),
              ListTile(title: Text('- Menampilkan kontak untuk informasi jika ada kendala')),
              ListTile(title: Text('- Menampilkan riwayat masuk dan keluar kendaraan')),
            ],
          ),
          ExpansionTile(
            title: Text(
              '2. Kendaraan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              ListTile(title: Text('- Menambahkan kendaraan baru')),
              ListTile(title: Text('- Melihat daftar kendaraan yang telah ditambahkan')),
              ListTile(title: Text('- Menghapus atau mengedit kendaraan')),
            ],
          ),
          ExpansionTile(
            title: Text(
              '3. QR Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              ListTile(title: Text('- Menampilkan QR Code untuk proses masuk/keluar parkir')),
            ],
          ),
          ExpansionTile(
            title: Text(
              '4. Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              ListTile(title: Text('- Menampilkan riwayat transaksi parkir lengkap')),
              ListTile(title: Text('- Menyimpan catatan waktu masuk dan keluar')),
            ],
          ),
        ],
      ),
    );
  }
}
