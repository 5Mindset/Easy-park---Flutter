import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'package:easy_park/services/auth_service.dart';
import 'package:easy_park/constants/api_config.dart';

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userData = prefs.getString('user');

      if (userData != null) {
        Map<String, dynamic> user = jsonDecode(userData);

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
          
          // Clean up date format if needed
          if (user['date_of_birth'] != null && user['date_of_birth'].isNotEmpty) {
            try {
              // Parse the date regardless of its format, then reformat it
              DateTime dateTime = DateTime.parse(user['date_of_birth']);
              _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(dateTime);
            } catch (e) {
              // If parsing fails, use the raw value
              _dateOfBirthController.text = user['date_of_birth'];
              debugPrint('Error parsing date: $e');
            }
          }
        });

        debugPrint('Profile image URL loaded: $_profileImageUrl');
      } else {
        debugPrint('No user data found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: Colors.green,
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

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfBirthController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_dateOfBirthController.text)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF130160),
            colorScheme: const ColorScheme.light(primary: Color(0xFF130160)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Format the date without time component
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
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
            content: Text('Nomor telepon harus berupa angka dan antara 8-20 digit'),
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
        DateFormat('yyyy-MM-dd').parseStrict(dateOfBirth);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format tanggal tidak valid (YYYY-MM-DD)'),
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
      final result = await AuthService.updateProfile(
        name: name.isNotEmpty ? name : null,
        email: email.isNotEmpty ? email : null,
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
        address: address.isNotEmpty ? address : null,
        nim: nim.isNotEmpty ? nim : null,
        fullName: fullName.isNotEmpty ? fullName : null,
        dateOfBirth: dateOfBirth.isNotEmpty ? dateOfBirth : null,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            _displayName = name.isNotEmpty ? name : _displayName;
            _displayEmail = email.isNotEmpty ? email : _displayEmail;
            _profileImageUrl = result['user']['image'];
            
            // Also update local user data
            _updateLocalUserData(result['user']);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Profil berhasil diperbarui'),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
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
          ),
        );
      }
    }
  }
  
  // Helper method to update local user data in SharedPreferences
  Future<void> _updateLocalUserData(Map<String, dynamic> userData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? existingUserData = prefs.getString('user');
      
      if (existingUserData != null) {
        Map<String, dynamic> user = jsonDecode(existingUserData);
        
        // Update with new data
        user.addAll(userData);
        
        // Clean date format if needed
        if (user['date_of_birth'] != null && user['date_of_birth'].toString().contains('T')) {
          try {
            DateTime dateTime = DateTime.parse(user['date_of_birth']);
            user['date_of_birth'] = DateFormat('yyyy-MM-dd').format(dateTime);
          } catch (e) {
            debugPrint('Error formatting date for local storage: $e');
          }
        }
        
        await prefs.setString('user', jsonEncode(user));
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
            ),
          );

          if (result['success']) {
            String? newProfileImageUrl = result['user']?['image'] ?? result['image'];

            if (newProfileImageUrl != null) {
              debugPrint('New profile image URL: $newProfileImageUrl');

              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? userData = prefs.getString('user');

              if (userData != null) {
                Map<String, dynamic> user = jsonDecode(userData);
                user['image'] = newProfileImageUrl;
                await prefs.setString('user', jsonEncode(user));

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
          ),
        );
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.33,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF130160), Color(0xFF2D1B89)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 16,
            child: TextButton(
              onPressed: _handleLogout,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Log out',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _showImageSourceOptions,
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                    ? Image.network(
                                        '$baseUrl/$_profileImageUrl',
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF130160)),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          debugPrint('Failed to load profile image: $error');
                                          return SvgPicture.asset(
                                            'assets/profile.svg',
                                            fit: BoxFit.cover,
                                            width: 80,
                                            height: 80,
                                          );
                                        },
                                      )
                                    : SvgPicture.asset(
                                        'assets/profile.svg',
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF130160),
                                  shape: BoxShape.circle,
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
                      const SizedBox(height: 8),
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _displayEmail,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _showImageSourceOptions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Edit foto profil'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      children: [
                        _buildTextField(
                            'Username', _usernameController, 'Brandone Louis'),
                        const SizedBox(height: 16),
                        _buildTextField('NIM', _nimController, 'E1234567890'),
                        const SizedBox(height: 16),
                        _buildTextField(
                            'Nama Lengkap', _fullNameController, 'Brandone Louis Smith'),
                        const SizedBox(height: 16),
                        _buildDateField(
                            'Tanggal Lahir', _dateOfBirthController, '1990-01-01'),
                        const SizedBox(height: 16),
                        _buildTextField(
                            'Alamat', _alamatController, 'California, United States'),
                        const SizedBox(height: 16),
                        _buildTextField('Email', _emailController, 'Brandonelouis@gmail.com'),
                        const SizedBox(height: 16),
                        _buildTextField('No Telp', _noTelpController, '619 3456 7890'),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleUpdateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF130160),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'EDIT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDateField(
      String label, TextEditingController controller, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.calendar_today,
                color: Colors.grey,
              ),
              onPressed: () => _selectDate(context),
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}