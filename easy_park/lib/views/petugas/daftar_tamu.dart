import 'package:flutter/material.dart';

// Pindahin ke atas duluan biar dikenali
class Guest {
  final String name;
  final String date;
  final String time;
  final String imageUrl;

  Guest({
    required this.name,
    required this.date,
    required this.time,
    required this.imageUrl,
  });
}

class DaftarTamu extends StatelessWidget {
  const DaftarTamu({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Guest> guests = [
      Guest(
        name: 'Bapak Arifin',
        date: '21/03/2025',
        time: '13.00',
        imageUrl:
            'https://cdn.pixabay.com/photo/2020/02/21/20/57/car-4872167_1280.jpg',
      ),
      Guest(
        name: 'Bapak Senpai',
        date: '21/03/2025',
        time: '13.00',
        imageUrl:
            'https://cdn.pixabay.com/photo/2016/11/22/07/09/lamborghini-1845714_1280.jpg',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFAFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Daftar Tamu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0)
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '7 Januari',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: (guests.length / 2).ceil(),
                  itemBuilder: (context, rowIndex) {
                    final start = rowIndex * 2;
                    final end = (start + 2).clamp(0, guests.length);
                    final rowGuests = guests.sublist(start, end);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: rowGuests
                          .map((guest) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GuestCard(guest: guest),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class GuestCard extends StatelessWidget {
  final Guest guest;

  const GuestCard({super.key, required this.guest});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              guest.imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(guest.date),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(guest.time),
                ),
                const SizedBox(height: 8),
                Center(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                    ),
                    child: const Text(
                      'KELUAR',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
