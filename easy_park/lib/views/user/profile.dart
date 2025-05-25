import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:easy_park/views/user/login_screen.dart';
import 'package:easy_park/services/auth_service.dart';
import 'package:easy_park/constants/api_config.dart';
import 'package:easy_park/services/local_db_service.dart';
import 'package:intl/intl.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noTelpController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();

  bool _isLoading = false;

  // State variables
  String _displayName = 'User';
  String _displayEmail = 'user@example.com';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final savedUser = await LocalDbService.getLogin();
      if (savedUser != null) {
        final user = jsonDecode(savedUser['user_json'] as String);

        setState(() {
          _displayName = user['name'] ?? 'User';
          _displayEmail = user['email'] ?? 'user@example.com';
          _profileImageUrl = user['image'];

          _usernameController.text = user['name'] ?? '';
          _alamatController.text = user['address'] ?? '';
          _emailController.text = user['email'] ?? '';
          _noTelpController.text = user['phone_number'] ?? '';
          _nimController.text = user['nim'] ?? '';
          _fullNameController.text = user['full_name'] ?? '';

          // Clean up date format if needed - convert to DD-MM-YYYY format
          if (user['date_of_birth'] != null &&
              user['date_of_birth'].isNotEmpty) {
            try {
              // Parse the date regardless of its format, then reformat it to DD-MM-YYYY
              DateTime dateTime = DateTime.parse(user['date_of_birth']);
              _dateOfBirthController.text =
                  DateFormat('dd-MM-yyyy').format(dateTime);
            } catch (e) {
              // If parsing fails, use the raw value
              _dateOfBirthController.text = user['date_of_birth'];
              debugPrint('Error parsing date: $e');
            }
          }
        });

        debugPrint('Profile image URL loaded: $_profileImageUrl');
      } else {
        debugPrint('No user data found in LocalDbService');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Clear login data from LocalDbService
      await LocalDbService.deleteLogin();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Function to validate email format
  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(email);
  }

  // Function to check if email is from a valid domain
  bool _hasValidDomain(String email) {
    if (!email.contains('@')) return false;
    final domain = email.split('@')[1].toLowerCase();
    return domain.isNotEmpty && domain.contains('.');
  }

  // Date picker handler
Future<void> _selectDate(BuildContext context) async {
  // Parse current date from controller
  DateTime initialDate = DateTime.now();
  if (_dateOfBirthController.text.isNotEmpty) {
    try {
      // Try to parse DD-MM-YYYY format
      List<String> dateParts = _dateOfBirthController.text.split('-');
      if (dateParts.length == 3) {
        int day = int.parse(dateParts[0]);
        int month = int.parse(dateParts[1]);
        int year = int.parse(dateParts[2]);
        initialDate = DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          primaryColor: const Color(0xFF130160),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF130160),
          ),
          buttonTheme: const ButtonThemeData(
            textTheme: ButtonTextTheme.primary,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    // Format as DD-MM-YYYY
    String formattedDate = DateFormat('dd-MM-yyyy').format(picked);
    _dateOfBirthController.text = formattedDate;
  }
}

  Future<void> _handleUpdateProfile() async {
    final name = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phoneNumber = _noTelpController.text.trim();
    final address = _alamatController.text.trim();
    final nim = _nimController.text.trim();
    final fullName = _fullNameController.text.trim();
    final dateOfBirth = _dateOfBirthController.text.trim();

    // Validation checks based on backend rules
    if (name.isNotEmpty && name.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username maksimal 100 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (email.isNotEmpty) {
      if (!_isValidEmail(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format email tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_hasValidDomain(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Domain email tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (phoneNumber.isNotEmpty) {
      if (!RegExp(r'^\+?[0-9]{8,20}$').hasMatch(phoneNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Nomor telepon harus berupa angka dan antara 8-20 digit'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (address.isNotEmpty && address.length > 255) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat maksimal 255 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (nim.isNotEmpty && (nim.length < 8 || nim.length > 15)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIM harus antara 8-15 digit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (fullName.isNotEmpty) {
      if (fullName.length > 255) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama lengkap maksimal 255 karakter'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(fullName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama lengkap hanya boleh berisi huruf dan spasi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (dateOfBirth.isNotEmpty) {
      try {
        // Validate DD-MM-YYYY format and convert to YYYY-MM-DD for backend
        final parts = dateOfBirth.split('-');
        if (parts.length != 3) throw Exception('Invalid format');

        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        final date = DateTime(year, month, day);
        // Validate date is reasonable
        if (date.isAfter(DateTime.now()) || date.year < 1900) {
          throw Exception('Invalid date range');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format tanggal tidak valid (DD-MM-YYYY)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert DD-MM-YYYY to YYYY-MM-DD for backend
      String? backendDateFormat;
      if (dateOfBirth.isNotEmpty) {
        final parts = dateOfBirth.split('-');
        backendDateFormat = '${parts[2]}-${parts[1]}-${parts[0]}'; // YYYY-MM-DD
      }

      final result = await AuthService.updateProfile(
        name: name.isNotEmpty ? name : null,
        email: email.isNotEmpty ? email : null,
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
        address: address.isNotEmpty ? address : null,
        nim: nim.isNotEmpty ? nim : null,
        fullName: fullName.isNotEmpty ? fullName : null,
        dateOfBirth: backendDateFormat,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            _displayName = name.isNotEmpty ? name : _displayName;
            _displayEmail = email.isNotEmpty ? email : _displayEmail;
            _profileImageUrl = result['user']['image'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Profil berhasil diperbarui'),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper method to update local user data in LocalDbService
  Future<void> _updateLocalUserData(Map<String, dynamic> userData) async {
    try {
      final savedUser = await LocalDbService.getLogin();
      if (savedUser != null) {
        final currentUser = jsonDecode(savedUser['user_json'] as String);
        // Update with new data
        currentUser.addAll(userData);

        // Clean date format if needed - convert to DD-MM-YYYY for display
        if (currentUser['date_of_birth'] != null &&
            currentUser['date_of_birth'].toString().contains('T')) {
          try {
            DateTime dateTime = DateTime.parse(currentUser['date_of_birth']);
            currentUser['date_of_birth'] =
                DateFormat('dd-MM-yyyy').format(dateTime);
          } catch (e) {
            debugPrint('Error formatting date for local storage: $e');
          }
        }

        await LocalDbService.saveLogin(
          email: savedUser['email'] as String,
          token: savedUser['token'] as String,
          role: savedUser['role'] as String,
          userJson: jsonEncode(currentUser),
        );
      }
    } catch (e) {
      debugPrint('Error updating local user data: $e');
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        debugPrint('Selected image path: ${imageFile.path}');
        debugPrint('File size: ${await imageFile.length()} bytes');

        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        final result = await AuthService.uploadProfileImage(imageFile);

        debugPrint('Upload response: $result');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Proses upload selesai'),
              backgroundColor: result['success'] ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );

          if (result['success']) {
            String? newProfileImageUrl =
                result['user']?['image'] ?? result['image'];

            if (newProfileImageUrl != null) {
              debugPrint('New profile image URL: $newProfileImageUrl');

              final savedUser = await LocalDbService.getLogin();
              if (savedUser != null) {
                final user = jsonDecode(savedUser['user_json'] as String);
                user['image'] = newProfileImageUrl;
                await LocalDbService.saveLogin(
                  email: savedUser['email'] as String,
                  token: savedUser['token'] as String,
                  role: savedUser['role'] as String,
                  userJson: jsonEncode(user),
                );

                setState(() {
                  _profileImageUrl = newProfileImageUrl;
                });
              }
            } else {
              debugPrint('No image URL in response, reloading user data');
              await _loadUserData();
            }
          }
        }
      } else {
        debugPrint('No image selected');
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload gambar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF130160),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF130160).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      color: Color(0xFF130160),
                    ),
                  ),
                  title: const Text(
                    'Ambil dari Kamera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF130160).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Color(0xFF130160),
                    ),
                  ),
                  title: const Text(
                    'Pilih dari Galeri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade50,
    body: Stack(
      children: [
        // Header gradient background with proper height and rounded bottom
        Container(
          height: MediaQuery.of(context).size.height * 0.35,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF130160), Color(0xFF2D1B89)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),

        // Logout button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextButton.icon(
              onPressed: () async {
                await _handleLogout(context);
              },
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Log out',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // Profile section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    // Profile image with shadow
                    GestureDetector(
                      onTap: _isLoading ? null : _showImageSourceOptions,
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImageUrl != null &&
                                      _profileImageUrl!.isNotEmpty
                                  ? Image.network(
                                      '$baseUrl/$_profileImageUrl',
                                      fit: BoxFit.cover,
                                      width: 90,
                                      height: 90,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF130160)),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        debugPrint(
                                            'Failed to load profile image: $error');
                                        return Container(
                                          padding: const EdgeInsets.all(20),
                                          child: SvgPicture.asset(
                                            'assets/profile.svg',
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(20),
                                      child: SvgPicture.asset(
                                        'assets/profile.svg',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF130160),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name and email
                    Text(
                      _displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Edit photo button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoading ? null : _showImageSourceOptions,
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 18,
                        ),
                        label: const Text(
                          'Edit foto profil',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form section with proper padding
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ListView(
                      children: [
                        _buildTextField('Username', _usernameController,
                            'Brandone Louis'),
                        const SizedBox(height: 20),
                        _buildTextField('NIM', _nimController, 'E1234567890'),
                        const SizedBox(height: 20),
                        _buildTextField('Nama Lengkap', _fullNameController,
                            'Brandone Louis Smith'),
                        const SizedBox(height: 20),
                        _buildDateField('Tanggal Lahir',
                            _dateOfBirthController, '01-01-1990'),
                        const SizedBox(height: 20),
                        _buildTextField('Alamat', _alamatController,
                            'California, United States'),
                        const SizedBox(height: 20),
                        _buildTextField('Email', _emailController,
                            'Brandonelouis@gmail.com'),
                        const SizedBox(height: 20),
                        // Added missing No Telp field
                        _buildTextField('No Telp', _noTelpController,
                            '+62 812 3456 7890'),
                        const SizedBox(
                            height: 30), // Increased spacing before button

                        // Update button with consistent spacing
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF130160), Color(0xFF2D1B89)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF130160).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _handleUpdateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'PERBARUI PROFIL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(
                            height: 30), // Bottom padding for scroll
                      ],
                    ),
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

  Widget _buildTextField(
      String label, TextEditingController controller, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF130160)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Build date field widget
Widget _buildDateField(String label, TextEditingController controller, String placeholder) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => _selectDate(context),
        child: AbsorbPointer(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              suffixIcon: const Icon(
                Icons.calendar_today,
                color: Color(0xFF130160),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF130160),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    ],
  );
}
}
