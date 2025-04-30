import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_park/services/auth_service.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.dmSansTextTheme(),
      ),
      home: const RegistrationScreen(),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _namaLengkapController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController(); // New controller for Phone Number
  final TextEditingController _addressController = TextEditingController(); // New controller for Address

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Password strength indicators (still tracked for validation, but not displayed)
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nimController.dispose();
    _namaLengkapController.dispose();
    _tanggalLahirController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
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
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF3D09D9),
            colorScheme: const ColorScheme.light(primary: Color(0xFF3D09D9)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Transform.translate(
                    offset: const Offset(-25, 0),
                    child: SvgPicture.asset(
                      'assets/easy.svg',
                      height: 40,
                      width: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                Center(
                  child: Text(
                    'Daftar',
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A45),
                    ),
                  ),
                ),

                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Mari mulai memarkirkan kendaraan anda\nbersama kami',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _buildLabel('Username'),
                _buildUsernameField(),

                const SizedBox(height: 16),

                _buildLabel('Email'),
                _buildEmailField(),

                const SizedBox(height: 16),

                _buildLabel('NIM'),
                _buildNimField(),

                const SizedBox(height: 16),

                _buildLabel('Nama Lengkap'),
                _buildNamaLengkapField(),

                const SizedBox(height: 16),

                _buildLabel('Tanggal Lahir'),
                _buildTanggalLahirField(),

                const SizedBox(height: 16),

                _buildLabel('Nomor Telepon'),
                _buildPhoneNumberField(), // New Phone Number field

                const SizedBox(height: 16),

                _buildLabel('Alamat'),
                _buildAddressField(), // New Address field

                const SizedBox(height: 16),

                _buildLabel('Password'),
                _buildPasswordField(
                  obscureText: !_isPasswordVisible,
                  controller: _passwordController,
                  validator: _validatePassword,
                  toggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),

                const SizedBox(height: 16),

                _buildLabel('Konfirmasi Password'),
                _buildConfirmPasswordField(),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D09D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Text(
                            'DAFTAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah mempunyai akun?',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF666666)),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Masuk',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF9228),
                            decoration: TextDecoration.underline,
                            decorationThickness: 1.0,
                            decorationColor: const Color(0xFFFF9228),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A45),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: 'Brandone Louis',
        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D09D9)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Username tidak boleh kosong';
        }
        if (value.length < 3) {
          return 'Username minimal 3 karakter';
        }
        if (value.length > 30) {
          return 'Username maksimal 30 karakter';
        }
        if (!RegExp(r'^[a-zA-Z0-9_\s]+$').hasMatch(value)) {
          return 'Username hanya boleh huruf, angka, spasi dan underscore';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: 'Brandonelouis@gmail.com',
        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D09D9)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email tidak boleh kosong';
        }
        if (!_isValidEmail(value)) {
          return 'Format email tidak valid';
        }
        if (!_hasValidDomain(value)) {
          return 'Domain email tidak valid';
        }
        return null;
      },
    );
  }

  Widget _buildNimField() {
    return TextFormField(
      controller: _nimController,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: 'E1234567890',
        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D09D9)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'NIM tidak boleh kosong';
        }
        if (value.length < 8 || value.length > 15) {
          return 'NIM harus antara 8-15 digit';
        }
        return null;
      },
    );
  }

  Widget _buildNamaLengkapField() {
    return TextFormField(
      controller: _namaLengkapController,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: 'Brandone Louis Smith',
        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D09D9)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nama lengkap tidak boleh kosong';
        }
        if (value.length < 3) {
          return 'Nama lengkap minimal 3 karakter';
        }
        if (value.length > 50) {
          return 'Nama lengkap maksimal 50 karakter';
        }
        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
          return 'Nama lengkap hanya boleh berisi huruf dan spasi';
        }
        return null;
      },
    );
  }

  Widget _buildTanggalLahirField() {
    return TextFormField(
      controller: _tanggalLahirController,
      readOnly: true,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'YYYY-MM-DD',
        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D09D9)),
        ),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.calendar_today,
            color: Color(0xFF666666),
          ),
          onPressed: () => _selectDate(context),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tanggal lahir tidak boleh kosong';
        }
        try {
          DateFormat('yyyy-MM-dd').parseStrict(value);
        } catch (e) {
          return 'Format tanggal tidak valid (YYYY-MM-DD)';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      controller: _phoneNumberController,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: '081234567890',
        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D09D9)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nomor telepon tidak boleh kosong';
        }
        if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value)) {
          return 'Nomor telepon harus berupa angka dan antara 8-15 digit';
        }
        return null;
      },
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      textInputAction: TextInputAction.next,
      maxLines: 3, // Allow multiple lines for address
      decoration: InputDecoration(
        hintText: 'Jl. Contoh No. 123, Kota Contoh',
        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D09D9)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Alamat tidak boleh kosong';
        }
        if (value.length < 5) {
          return 'Alamat minimal 5 karakter';
        }
        if (value.length > 255) {
          return 'Alamat maksimal 255 karakter';
        }
        return null;
      },
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password harus mengandung huruf besar';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password harus mengandung angka';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password harus mengandung karakter khusus';
    }
    return null;
  }

  Widget _buildPasswordField({
    required bool obscureText,
    required TextEditingController controller,
    required VoidCallback toggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'password123',
        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D09D9)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF666666),
          ),
          onPressed: toggleVisibility,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        hintText: 'password123',
        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D09D9)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF666666),
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Konfirmasi password tidak boleh kosong';
        }
        if (value != _passwordController.text) {
          return 'Password dan konfirmasi tidak sama';
        }
        return null;
      },
    );
  }

  Future<void> _handleRegister() async {
    // Menghilangkan fokus keyboard
    FocusScope.of(context).unfocus();

    // Validasi form
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final nim = _nimController.text.trim();
      final namaLengkap = _namaLengkapController.text.trim();
      final tanggalLahir = _tanggalLahirController.text;
      final phoneNumber = _phoneNumberController.text.trim();
      final address = _addressController.text.trim();

      // Implementasi throttling sederhana untuk mencegah spam pendaftaran
      await Future.delayed(const Duration(milliseconds: 300));

      // Menggunakan try-catch untuk menangkap error dari API
      final result = await AuthService.register(
        name: name,
        email: email,
        password: password,
        nim: nim,
        fullName: namaLengkap,
        dateOfBirth: tanggalLahir,
        phoneNumber: phoneNumber,
        address: address,
      );

      if (result['success']) {
        // Menampilkan pesan sukses
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Berhasil daftar'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Penanganan navigasi berdasarkan role
        if (result['redirect_to'] == 'mahasiswaHome') {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/mahasiswaHome');
        } else {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        // Menampilkan pesan error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal daftar'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}