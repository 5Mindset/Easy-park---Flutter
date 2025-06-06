import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:easy_park/services/vehicle_service.dart';
import 'package:easy_park/widgets/Bottom_Navigation.dart';
import 'dart:math';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
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
    _fetchVehicleTypes();
  }

  Future<void> _fetchVehicleTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final typeResult = await VehicleService.getVehicleTypes();
    if (!typeResult['success']) {
      setState(() {
        _isLoading = false;
        _errorMessage = typeResult['message'];
      });
      return;
    }

    setState(() {
      _types = List<Map<String, dynamic>>.from(typeResult['data']);
      _isLoading = false;
    });
  }

  Future<void> _fetchBrandsByType() async {
    setState(() {
      _brands = [];
      _models = [];
      _selectedBrandId = null;
      _selectedModelId = null;
      _modelController.clear();
      _isLoading = true;
      _errorMessage = null;
    });

    if (_selectedTypeId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final brandResult =
        await VehicleService.getVehicleBrandsByType(_selectedTypeId!);
    setState(() {
      if (brandResult['success']) {
        _brands = List<Map<String, dynamic>>.from(brandResult['data']);
      } else {
        _errorMessage = brandResult['message'];
        _brands = [];
      }
      _isLoading = false;
    });
  }

  Future<void> _fetchModelsByBrand() async {
    setState(() {
      _models = [];
      _selectedModelId = null;
      _modelController.clear();
      _isLoading = true;
      _errorMessage = null;
    });

    if (_selectedBrandId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final modelResult =
        await VehicleService.getVehicleModelsByBrand(_selectedBrandId!);
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
        _modelController.text.isEmpty ||
        _selectedBrandId == null ||
        _selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field wajib')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check vehicle limit (HARDCODED: 3 vehicles max)
      const int VEHICLE_LIMIT = 3;

      final vehicleCountResult = await VehicleService.getUserVehicleCount();

      if (!vehicleCountResult['success']) {
        setState(() {
          _isLoading = false;
          _errorMessage = vehicleCountResult['message'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal memeriksa jumlah kendaraan: ${vehicleCountResult['message']}')),
        );
        return;
      }

      final int currentVehicleCount = vehicleCountResult['data']['count'] ?? 0;

      if (currentVehicleCount >= VEHICLE_LIMIT) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Maksimal $VEHICLE_LIMIT kendaraan per mahasiswa';
        });

        // Show warning dialog instead of navigation
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
              title: Text(
                'Batas Maksimal Tercapai',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Anda sudah mencapai batas maksimal $VEHICLE_LIMIT kendaraan per mahasiswa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car, color: Colors.red[600]),
                        SizedBox(width: 8),
                        Text(
                          '$currentVehicleCount / $VEHICLE_LIMIT Kendaraan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Silakan hapus salah satu kendaraan yang sudah terdaftar terlebih dahulu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
                    Navigator.of(context).pop(); // Kembali ke halaman sebelumnya (misalnya BottomNavigation)
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          },
        );
        return;
      }

      // Check if the entered model exists in _models
      final modelName = _modelController.text.trim();
      final existingModel = _models.firstWhere(
        (m) => m['name'].toString().toLowerCase() == modelName.toLowerCase(),
        orElse: () => {},
      );

      if (existingModel.isNotEmpty) {
        // Use existing model ID
        _selectedModelId = existingModel['id'];
      } else {
        // Create new vehicle model
        final modelResult = await VehicleService.createVehicleModel(
          name: modelName,
          vehicleBrandId: _selectedBrandId!,
          vehicleTypeId: _selectedTypeId!,
        );

        if (!modelResult['success']) {
          setState(() {
            _isLoading = false;
            _errorMessage = modelResult['message'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Gagal membuat model: ${modelResult['message']}')),
          );
          return;
        }

        _selectedModelId = modelResult['data']['id'];

        // Optionally update _models to include the new model
        setState(() {
          _models.add(modelResult['data']);
        });
      }

      // Add vehicle
      final result = await VehicleService.addVehicle(
        plateNumber: _plateController.text,
        vehicleModelId: _selectedModelId!,
        stnkImage: _stnkImage,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Kendaraan berhasil ditambahkan (${currentVehicleCount + 1}/$VEHICLE_LIMIT)'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BottomNavigationWidget(initialTab: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${result['message']}\nDetails: ${result['error']}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
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
                ? Center(
                    child: Text(_errorMessage!, textAlign: TextAlign.center))
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
                                buildTextField('No Plat', _plateController,
                                    hint: 'P3333'),
                                buildDropdown(
                                  'Tipe',
                                  _types
                                      .map((t) => t['name'].toString())
                                      .toList(),
                                  _selectedTypeId != null
                                      ? _types.firstWhere((t) =>
                                          t['id'] == _selectedTypeId)['name']
                                      : null,
                                  (value) {
                                    setState(() {
                                      _selectedTypeId = value != null
                                          ? _types.firstWhere(
                                              (t) => t['name'] == value)['id']
                                          : null;
                                    });
                                    _fetchBrandsByType();
                                  },
                                  hint: 'Pilih Tipe',
                                ),
                                buildDropdown(
                                  'Merk',
                                  _brands
                                      .map((b) => b['name'].toString())
                                      .toList(),
                                  _selectedBrandId != null
                                      ? _brands.firstWhere((b) =>
                                          b['id'] == _selectedBrandId)['name']
                                      : null,
                                  (value) {
                                    setState(() {
                                      _selectedBrandId = value != null
                                          ? _brands.firstWhere(
                                              (b) => b['name'] == value)['id']
                                          : null;
                                    });
                                    _fetchModelsByBrand();
                                  },
                                  hint: 'Pilih Merk',
                                ),
                                buildAutocompleteTextField(
                                  'Model',
                                  _modelController,
                                  _models,
                                  hint: 'Masukkan Model',
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
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                          Icons.close,
                                                          size: 16,
                                                          color: Colors.red),
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
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_a_photo,
                                                      size: 30,
                                                      color:
                                                          Colors.grey.shade600),
                                                  const SizedBox(height: 10),
                                                  const Text(
                                                    'Unggah Foto STNK',
                                                    style: TextStyle(
                                                        color: Colors.grey),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    'Tap untuk mengambil foto atau memilih dari galeri',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade600),
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(
                                            color: Colors.purple),
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

  Widget buildTextField(String label, TextEditingController controller,
      {String? hint}) {
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdown(String label, List<String> items, String? selectedItem,
      ValueChanged<String?> onChanged,
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
            hint: Text(hint ?? 'Pilih',
                style: TextStyle(color: Colors.grey.shade600)),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAutocompleteTextField(String label,
      TextEditingController controller, List<Map<String, dynamic>> models,
      {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return models
                  .map((m) => m['name'].toString())
                  .where((String option) {
                return option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              controller.text = selection;
              final selectedModel =
                  models.firstWhere((m) => m['name'] == selection);
              setState(() {
                _selectedModelId = selectedModel['id'];
              });
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController fieldController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              fieldController.text = controller.text;
              return TextField(
                controller: fieldController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                onChanged: (value) {
                  controller.text = value;
                  // Clear selected model ID if the user types a new value
                  setState(() {
                    _selectedModelId = null;
                  });
                },
              );
            },
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
      painter:
          _DashedRectPainter(color: color, strokeWidth: strokeWidth, gap: gap),
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

    void drawDashedLine(
        double startX, double startY, double endX, double endY) {
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
