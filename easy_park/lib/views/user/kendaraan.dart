import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const Kendaraan());
}

class Kendaraan extends StatelessWidget {
  const Kendaraan({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Easy Park',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const VehicleRegistrationScreen(),
    );
  }
}

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _brandController.dispose();
    _typeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 7),

              const Text(
                'Kendaraan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 2),

              const Text(
                'Kami tidak memiliki informasi kendaraan anda silahkan input informasi kendaraan anda',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildTextField('Nama Kendaraan', _nameController, hint: "Scoopy"),
                      buildTextField('No Plat', _plateController, hint: "P3333"),
                      Row(
                        children: [
                          Expanded(child: buildTextField('Merk', _brandController, hint: "Honda")),
                          const SizedBox(width: 16),
                          Expanded(child: buildTextField('Tipe', _typeController, hint: "sepeda listrik")),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: buildTextField('Model', _modelController, hint: "Fashion Blue")),
                          const SizedBox(width: 16),
                          Expanded(child: buildTextField('Warna', _colorController, hint: "hitam")),
                        ],
                      ),
                      const SizedBox(height: 5),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Foto stnk',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DashedRect(
                          color: Colors.grey.shade400,
                          gap: 5.0,
                          strokeWidth: 1.2,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Unggah Gambar',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                Icon(Icons.arrow_downward, color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Aksi konfirmasi
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.purple),
                            ),
                          ),
                          child: const Text(
                            'KONFIRMASI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// DashedRect Widget
class DashedRect extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double gap;

  const DashedRect({
    Key? key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color, strokeWidth: strokeWidth, gap: gap),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    final space = gap;

    void drawDashedLine(double startX, double startY, double endX, double endY) {
      final dx = endX - startX;
      final dy = endY - startY;
      final distance = sqrt(dx * dx + dy * dy);
      final dashCount = distance / (dashWidth + space);
      final dxStep = dx / dashCount;
      final dyStep = dy / dashCount;

      double x = startX, y = startY;
      for (int i = 0; i < dashCount; i++) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x + dxStep * 0.5, y + dyStep * 0.5),
          paint,
        );
        x += dxStep;
        y += dyStep;
      }
    }

    drawDashedLine(0, 0, size.width, 0); // Top
    drawDashedLine(size.width, 0, size.width, size.height); // Right
    drawDashedLine(size.width, size.height, 0, size.height); // Bottom
    drawDashedLine(0, size.height, 0, 0); // Left
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
