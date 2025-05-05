import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_park/services/auth_service.dart';
import 'package:easy_park/views/auth/forgot_password_screen.dart';
import 'register_screen.dart';
import 'package:easy_park/widgets/Bottom_Navigation.dart';
import 'package:easy_park/widgets/Drawer_Navigation.dart';
import 'package:easy_park/services/local_db_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _isSubmitting = false;

  // State variables to track field status
  bool _emailHasError = false;
  bool _passwordHasError = false;
  String _emailErrorText = '';
  String _passwordErrorText = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email validation
  bool _isValidEmail(String email) {
    final emailRegExp =
        RegExp(r'^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegExp.hasMatch(email);
  }

  // Password validation (min 6 chars with at least 1 number)
  bool _isValidPassword(String password) {
    return password.length >= 6 && password.contains(RegExp(r'[0-9]'));
  }

  // Show a snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF3D09D9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Validate email field on change and update UI accordingly
  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailHasError = true;
        _emailErrorText = 'Email tidak boleh kosong';
      } else if (!_isValidEmail(value)) {
        _emailHasError = true;
        _emailErrorText = 'Format email tidak valid';
      } else {
        _emailHasError = false;
        _emailErrorText = '';
      }
    });
  }

  // Validate password field on change and update UI accordingly
  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordHasError = true;
        _passwordErrorText = 'Password tidak boleh kosong';
      } else if (value.length < 6) {
        _passwordHasError = true;
        _passwordErrorText = 'Password minimal 6 karakter';
      } else if (!value.contains(RegExp(r'[0-9]'))) {
        _passwordHasError = true;
        _passwordErrorText = 'Password harus mengandung minimal 1 angka';
      } else {
        _passwordHasError = false;
        _passwordErrorText = '';
      }
    });
  }

  // Full form validation and login process
  Future<void> _login() async {
    // Validate both fields on button press
    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);

    // If any field has errors, stop the login process
    if (_emailHasError || _passwordHasError) {
      _showSnackBar('Harap perbaiki kesalahan pada form', isError: true);
      return;
    }

    // Show loading state
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Call AuthService.login to perform API login
      final result = await AuthService.login(
        _emailController.text,
        _passwordController.text,
      );

      debugPrint('Login result: $result');

      if (result['success']) {
        // Show API-provided notification
        _showSnackBar(result['message']);

        // Get redirect_to and role
        final redirectTo = result['redirect_to'];
        final role = result['role'];
        debugPrint('Redirect to: $redirectTo, Role: $role');

        // Validate role
        if (!['mahasiswa', 'petugas', 'admin'].contains(role)) {
          _showSnackBar('Role tidak valid: $role', isError: true);
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        // Simpan ke SQLite
        try {
          await LocalDbService.saveLogin(
            email: _emailController.text,
            token: result['token'],
            role: role,
            userJson: jsonEncode(result['user']),
          );
          debugPrint('Saved to LocalDbService: email=${_emailController.text}, role=$role');
        } catch (e) {
          _showSnackBar('Gagal menyimpan data login: $e', isError: true);
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        // Map redirect_to to navigation target
        Widget? targetPage;
        if (redirectTo == 'Bottom_Navigation') {
          targetPage = const BottomNavigationWidget();
        } else if (redirectTo == 'petugasHome') {
          targetPage = const DrawerNavigationwidget();
        } else if (redirectTo == 'adminHome') {
          // Handle admin case (no AdminHomeWidget in Flutter)
          _showSnackBar('Admin dashboard not available in mobile app', isError: true);
          setState(() {
            _isSubmitting = false;
          });
          return;
        } else {
          _showSnackBar('Redirect tidak valid: $redirectTo', isError: true);
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        // Navigate after a delay to ensure snackbar is visible
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => targetPage!),
          );
        }
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: ${e.toString()}', isError: true);
    } finally {
      // Hide loading state
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SVG Logo in top-left corner
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

                  // Header
                  Center(
                    child: Text(
                      'Masuk',
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D0140),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subheader
                  Center(
                    child: Text(
                      'Ayo parkirkan kendaraan anda lebih aman\nbersama kami',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: const Color(0xFF524B6B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Email Label
                  Text(
                    'Email',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0D0140),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Email Input with validation
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: _validateEmail,
                    decoration: InputDecoration(
                      hintText: 'Brandonkelious@gmail.com',
                      hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              _emailHasError ? Colors.red : Colors.grey[200]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              _emailHasError ? Colors.red : Colors.grey[300]!,
                        ),
                      ),
                      // Show error icon if there's an error
                      suffixIcon: _emailHasError
                          ? const Icon(Icons.error, color: Colors.red)
                          : _emailController.text.isNotEmpty
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : null,
                      // Show error message
                      errorText: _emailHasError ? _emailErrorText : null,
                      errorStyle: GoogleFonts.dmSans(
                        color: Colors.red,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Password Label
                  Text(
                    'Password',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0D0140),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Password Input with validation
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    onChanged: _validatePassword,
                    decoration: InputDecoration(
                      hintText: 'password123',
                      hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _passwordHasError
                              ? Colors.red
                              : Colors.grey[200]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _passwordHasError
                              ? Colors.red
                              : Colors.grey[300]!,
                        ),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show validation icon if password entered
                          if (_passwordController.text.isNotEmpty)
                            Icon(
                              _passwordHasError
                                  ? Icons.error
                                  : Icons.check_circle,
                              color:
                                  _passwordHasError ? Colors.red : Colors.green,
                            ),
                          // Show/hide password toggle
                          IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ],
                      ),
                      // Show error message
                      errorText: _passwordHasError ? _passwordErrorText : null,
                      errorStyle: GoogleFonts.dmSans(
                        color: Colors.red,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Lupa Password?',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF0D0140),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Button with loading state
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D09D9),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'MASUK',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Don't have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Anda belum mempunyai akun? ',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Daftar',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}