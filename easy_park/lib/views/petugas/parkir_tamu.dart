import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ParkirTamu extends StatefulWidget {
  const ParkirTamu({Key? key}) : super(key: key);

  @override
  State<ParkirTamu> createState() => _ParkirTamuState();
}

class _ParkirTamuState extends State<ParkirTamu> {
  final TextEditingController _namaController = TextEditingController();
  File? _imageFile;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendaraan (tamu)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gabungan title + subtitle
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Input kendaraan tamu dengan sesuai dan pasti",
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Nama tamu"),
              const SizedBox(height: 8),
              TextField(
                controller: _namaController,
                decoration: InputDecoration(
                  hintText: "pak masud",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 30),
              const Text("Foto kendaraan dari depan (plat nomer terlihat)"),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: DottedBorderBox(
                  child: _imageFile == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.cloud_upload,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("Unggah Gambar",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : Image.file(_imageFile!, height: 150),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF130160),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Implement konfirmasi logic
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      "KONFIRMASI",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          style: BorderStyle.solid,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: child),
    );
  }
}
