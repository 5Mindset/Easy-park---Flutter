// vehicle_edit_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:easy_park/services/vehicle_service.dart';
import 'package:easy_park/widgets/Bottom_Navigation.dart';
import 'dart:math';
import 'package:easy_park/constants/api_config.dart';

class VehicleEditScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleEditScreen({Key? key, required this.vehicle}) : super(key: key);

  @override
  State<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends State<VehicleEditScreen> {
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  int? _selectedBrandId;
  int? _selectedTypeId;
  int? _selectedModelId;
  File? _stnkImage;
  String? _existingStnkUrl;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _models = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate fields with vehicle data
    _plateController.text = widget.vehicle['plate_number'] ?? '';
    _modelController.text = widget.vehicle['model']?['name'] ?? '';
    _selectedModelId = widget.vehicle['model']?['id'];
    _selectedBrandId = widget.vehicle['model']?['vehicle_brand']?['id'];
    _selectedTypeId = widget.vehicle['model']?['vehicle_type']?['id'];
    
    // Configure STNK URL using the new function
    _existingStnkUrl = _configureStnkUrl(widget.vehicle['stnk_image']);
    
    _fetchVehicleTypes();
  }

  // Function to configure STNK URL properly
  String? _configureStnkUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }

    // Deteksi kalau belum ada "public/"
    if (!rawUrl.contains('public/')) {
      return 'https://webfw23.myhost.id/gol_bws3/public/storage/$rawUrl';
    } else {
      return 'https://webfw23.myhost.id/gol_bws3/storage/$rawUrl';
    }
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
      // Validate _selectedTypeId
      if (_selectedTypeId != null &&
          !_types.any((t) => t['id'] == _selectedTypeId)) {
        _selectedTypeId = null; // Reset if invalid
      }
      _isLoading = false;
    });

    await _fetchBrandsByType();
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
        // Restore selected brand if it exists in the list
        final originalBrandId =
            widget.vehicle['model']?['vehicle_brand']?['id'];
        if (originalBrandId != null &&
            _brands.any((b) => b['id'] == originalBrandId)) {
          _selectedBrandId = originalBrandId;
          _modelController.text = widget.vehicle['model']?['name'] ?? '';
          _selectedModelId = widget.vehicle['model']?['id'];
        }
      } else {
        _errorMessage = brandResult['message'];
        _brands = [];
      }
      _isLoading = false;
    });

    await _fetchModelsByBrand();
  }

  Future<void> _fetchModelsByBrand() async {
    setState(() {
      _models = [];
      _selectedModelId = null;
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
        // Restore selected model if it exists
        final originalModelId = widget.vehicle['model']?['id'];
        if (originalModelId != null &&
            _models.any((m) => m['id'] == originalModelId)) {
          _selectedModelId = originalModelId;
          _modelController.text = widget.vehicle['model']?['name'] ?? '';
        }
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

    // Check if the entered model exists in _models
    final modelName = _modelController.text.trim();
    final existingModel = _models.firstWhere(
      (m) => m['name'].toString().toLowerCase() == modelName.toLowerCase(),
      orElse: () => {},
    );

    if (existingModel.isNotEmpty) {
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
              content: Text('Gagal membuat model: ${modelResult['message']}')),
        );
        return;
      }

      _selectedModelId = modelResult['data']['id'];
      setState(() {
        _models.add(modelResult['data']);
      });
    }

    final result = await VehicleService.updateVehicle(
      vehicleId: widget.vehicle['id'],
      plateNumber: _plateController.text,
      vehicleModelId: _selectedModelId!,
      stnkImage: _stnkImage,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      Navigator.pop(context, result['data']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${result['message']}\nDetails: ${result['error']}')),
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
                          'Edit Kendaraan',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
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
                                      ? _types.firstWhere(
                                          (t) => t['id'] == _selectedTypeId,
                                          orElse: () => {'name': 'Pilih Tipe'},
                                        )['name']
                                      : null,
                                  (value) {
                                    setState(() {
                                      _selectedTypeId = value != null
                                          ? _types.firstWhere(
                                              (t) => t['name'] == value,
                                              orElse: () => {'id': null},
                                            )['id']
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
                                      ? _brands.firstWhere(
                                          (b) => b['id'] == _selectedBrandId,
                                          orElse: () => {'name': 'Pilih Merk'},
                                        )['name']
                                      : null,
                                  (value) {
                                    setState(() {
                                      _selectedBrandId = value != null
                                          ? _brands.firstWhere(
                                              (b) => b['name'] == value,
                                              orElse: () => {'id': null},
                                            )['id']
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
                                // Updated STNK image container with better URL handling
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
                                        : _existingStnkUrl != null &&
                                                _existingStnkUrl!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Image.network(
                                                      _existingStnkUrl!,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            value: loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        print(
                                                            'Error loading image: $error'); // Debug log
                                                        print(
                                                            'Attempting to load URL: $_existingStnkUrl'); // Debug log
                                                        return Container(
                                                          color: Colors
                                                              .grey.shade200,
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .broken_image,
                                                                size: 40,
                                                                color: Colors
                                                                    .grey
                                                                    .shade600,
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Gagal memuat gambar',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade600,
                                                                  fontSize: 12,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              TextButton(
                                                                onPressed: () {
                                                                  setState(() {
                                                                    // Re-configure URL and force rebuild
                                                                    _existingStnkUrl = _configureStnkUrl(widget.vehicle['stnk_image']);
                                                                  });
                                                                },
                                                                child:
                                                                    const Text(
                                                                  'Coba Lagi',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          11),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            _existingStnkUrl =
                                                                null;
                                                            _stnkImage = null;
                                                          });
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(4),
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: Colors.white,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                              Icons.close,
                                                              size: 16,
                                                              color:
                                                                  Colors.red),
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
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.add_a_photo,
                                                          size: 30,
                                                          color: Colors
                                                              .grey.shade600),
                                                      const SizedBox(
                                                          height: 10),
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
                                                        textAlign:
                                                            TextAlign.center,
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
              final selectedModel = models.firstWhere(
                (m) => m['name'] == selection,
                orElse: () => {'id': null},
              );
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

    drawDashedLine(0, 0, size.width, 0);
    drawDashedLine(size.width, 0, size.width, size.height);
    drawDashedLine(size.width, size.height, 0, size.height);
    drawDashedLine(0, size.height, 0, 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}