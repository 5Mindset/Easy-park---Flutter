import 'package:flutter/material.dart';

class DaftarMahasiswa extends StatelessWidget {
  DaftarMahasiswa({Key? key}) : super(key: key);

  final List<Mahasiswa> mahasiswaList = [
    Mahasiswa(
      nama: 'Bustanul',
      tanggal: '21/02/2024',
      waktu: '23.00',
      kode: 'P0210',
    ),
    Mahasiswa(
      nama: 'Bustanul',
      tanggal: '21/02/2024',
      waktu: '00.32',
      kode: 'P0210',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Daftar mahasiswa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.info, color: Colors.black, size: 20),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: mahasiswaList.length,
                  itemBuilder: (context, index) {
                    return MahasiswaCard(mahasiswa: mahasiswaList[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Mahasiswa {
  final String nama;
  final String tanggal;
  final String waktu;
  final String kode;

  Mahasiswa({
    required this.nama,
    required this.tanggal,
    required this.waktu,
    required this.kode,
  });
}

class MahasiswaCard extends StatelessWidget {
  final Mahasiswa mahasiswa;

  MahasiswaCard({Key? key, required this.mahasiswa}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.indigo,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mahasiswa.nama,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '${mahasiswa.tanggal}  ·  ${mahasiswa.waktu}',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  mahasiswa.kode,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
