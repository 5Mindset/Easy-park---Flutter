import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:easy_park/services/vehicle_service.dart';
import 'dart:math';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final TextEditingController _plateController = TextEditingController();
  int? _selectedBrandId;
  int? _selectedTypeId;
  int? _selectedModelId;
  File? _stnkImage;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _models = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fetch brands
    final brandResult = await VehicleService.getVehicleBrands();
    if (!brandResult['success']) {
      setState(() {
        _isLoading = false;
        _errorMessage = brandResult['message'];
      });
      return;
    }

    // Fetch types
    final typeResult = await VehicleService.getVehicleTypes();
    if (!typeResult['success']) {
      setState(() {
        _isLoading = false;
        _errorMessage = typeResult['message'];
      });
      return;
    }

    setState(() {
      _brands = List<Map<String, dynamic>>.from(brandResult['data']);
      _types = List<Map<String, dynamic>>.from(typeResult['data']);
      _isLoading = false;
    });
  }

  Future<void> _fetchModels() async {
    if (_selectedBrandId == null || _selectedTypeId == null) {
      setState(() {
        _models = [];
        _selectedModelId = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final modelResult = await VehicleService.getVehicleModels(_selectedBrandId!, _selectedTypeId!);
    setState(() {
      if (modelResult['success']) {
        _models = List<Map<String, dynamic>>.from(modelResult['data']);
      } else {
        _errorMessage = modelResult['message'];
        _models = [];
      }
      _isLoading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? selected = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (selected != null) {
        setState(() {
          _stnkImage = File(selected.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil gambar')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_plateController.text.isEmpty ||
        _selectedBrandId == null ||
        _selectedTypeId == null ||
        _selectedModelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await VehicleService.addVehicle(
      plateNumber: _plateController.text,
      vehicleModelId: _selectedModelId!,
      stnkImage: _stnkImage,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      final vehicle = result['data'];
      Navigator.pop(context, {
        'name': vehicle['model']['name']?.toString() ?? 'Unknown Model',
        'id': vehicle['plate_number']?.toString() ?? 'Unknown Plate',
        'brand': vehicle['model']['vehicle_brand']['name']?.toString() ?? 'Unknown Brand',
        'type': vehicle['model']['vehicle_type']['name']?.toString() ?? 'Unknown Type',
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result['message']}\nDetails: ${result['error']}')),
      );
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, textAlign: TextAlign.center))
                : Padding(
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
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                buildTextField('No Plat', _plateController, hint: 'P3333'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: buildDropdown(
                                        'Merk',
                                        _brands.map((b) => b['name'].toString()).toList(),
                                        _selectedBrandId != null
                                            ? _brands.firstWhere((b) => b['id'] == _selectedBrandId)['name']
                                            : null,
                                        (value) {
                                          setState(() {
                                            _selectedBrandId = _brands.firstWhere((b) => b['name'] == value)['id'];
                                            _selectedModelId = null;
                                            _fetchModels();
                                          });
                                        },
                                        hint: 'Pilih Merk',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: buildDropdown(
                                        'Tipe',
                                        _types.map((t) => t['name'].toString()).toList(),
                                        _selectedTypeId != null
                                            ? _types.firstWhere((t) => t['id'] == _selectedTypeId)['name']
                                            : null,
                                        (value) {
                                          setState(() {
                                            _selectedTypeId = _types.firstWhere((t) => t['name'] == value)['id'];
                                            _selectedModelId = null;
                                            _fetchModels();
                                          });
                                        },
                                        hint: 'Pilih Tipe',
                                      ),
                                    ),
                                  ],
                                ),
                                buildDropdown(
                                  'Model',
                                  _models.map((m) => m['name'].toString()).toList(),
                                  _selectedModelId != null
                                      ? _models.firstWhere((m) => m['id'] == _selectedModelId)['name']
                                      : null,
                                  (value) {
                                    setState(() {
                                      _selectedModelId = _models.firstWhere((m) => m['name'] == value)['id'];
                                    });
                                  },
                                  hint: 'Pilih Model',
                                ),
                                const SizedBox(height: 5),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Foto STNK',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _showImageSourceDialog,
                                  child: Container(
                                    width: double.infinity,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _stnkImage != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.file(
                                                  _stnkImage!,
                                                  fit: BoxFit.cover,
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _stnkImage = null;
                                                      });
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(Icons.close, size: 16, color: Colors.red),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : DashedRect(
                                            color: Colors.grey.shade400,
                                            gap: 5.0,
                                            strokeWidth: 1.2,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_a_photo, size: 30, color: Colors.grey.shade600),
                                                  const SizedBox(height: 10),
                                                  const Text(
                                                    'Unggah Foto STNK',
                                                    style: TextStyle(color: Colors.grey),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    'Tap untuk mengambil foto atau memilih dari galeri',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitForm,
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

  Widget buildDropdown(
      String label, List<String> items, String? selectedItem, ValueChanged<String?> onChanged,
      {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedItem,
            hint: Text(hint ?? 'Pilih', style: TextStyle(color: Colors.grey.shade600)),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
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