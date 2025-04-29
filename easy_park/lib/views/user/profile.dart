import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoading = false;

  // State variables
  String _displayName = 'User';
  String _displayEmail = 'user@example.com';
  String? _profileImageUrl; // This will hold the image URL from the backend

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
          _profileImageUrl = user['image']; // Use 'image' key as per backend response

          _usernameController.text = user['name'] ?? '';
          _alamatController.text = user['address'] ?? '';
          _emailController.text = user['email'] ?? '';
          _noTelpController.text = user['phone_number'] ?? '';
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

  Future<void> _handleUpdateProfile() async {
    final name = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phoneNumber = _noTelpController.text.trim();
    final address = _alamatController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phoneNumber.isEmpty ||
        address.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua field harus diisi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.updateProfile(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            _displayName = name;
            _displayEmail = email;
            _profileImageUrl = result['user']['image']; // Update image if changed
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

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image for faster upload
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

        // Upload the image file using AuthService
        final result = await AuthService.uploadProfileImage(imageFile);

        debugPrint('Upload response: $result');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Show feedback message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Proses upload selesai'),
              backgroundColor: result['success'] ? Colors.green : Colors.red,
            ),
          );

          if (result['success']) {
            // Update the profile image URL from the response
            String? newProfileImageUrl = result['user']?['image'] ?? result['image'];

            if (newProfileImageUrl != null) {
              debugPrint('New profile image URL: $newProfileImageUrl');

              // Update SharedPreferences with new image URL
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? userData = prefs.getString('user');

              if (userData != null) {
                Map<String, dynamic> user = jsonDecode(userData);
                user['image'] = newProfileImageUrl;
                await prefs.setString('user', jsonEncode(user));

                // Update UI
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
                                        '$baseUrl/$_profileImageUrl', // Use dynamic baseUrl
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
                        _buildTextField('Alamat', _alamatController,
                            'California, United States'),
                        const SizedBox(height: 16),
                        _buildTextField('Email', _emailController,
                            'Brandonelouis@gmail.com'),
                        const SizedBox(height: 16),
                        _buildTextField(
                            'No Telp', _noTelpController, '619 3456 7890'),
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
}