import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class MasterPasswordScreen extends StatefulWidget {
  const MasterPasswordScreen({super.key});

  @override
  State<MasterPasswordScreen> createState() => _MasterPasswordScreenState();
}

class _MasterPasswordScreenState extends State<MasterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isInitialized = false;
  bool _hasMasterPassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final hasPassword = await AuthService.instance.hasMasterPassword();
    if (mounted) {
      setState(() {
        _hasMasterPassword = hasPassword;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final password = _passwordController.text;

    try {
      if (!_hasMasterPassword) {
        // Create Flow
        final success = await AuthService.instance.setMasterPassword(password);
        if (success && mounted) {
          _navigateToHome();
        } else {
          setState(() {
            _errorMessage = 'Gagal menyimpan password. Coba lagi.';
          });
        }
      } else {
        // Login Flow
        final isValid = await AuthService.instance.verifyMasterPassword(password);
        if (isValid && mounted) {
          _navigateToHome();
        } else {
          setState(() {
            _errorMessage = 'Password Master salah!';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F12),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12), // Deep dark space background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon / Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x268B5CF6),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 48,
                          color: Color(0xFF8B5CF6), // Premium violet color
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      _hasMasterPassword ? 'Selamat Datang Kembali' : 'Setup Master Password',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _hasMasterPassword
                          ? 'Masukkan password utama Anda untuk mendekripsi data.'
                          : 'Buat satu password utama untuk mengamankan seluruh sandi Anda. Password ini tidak disimpan secara mentah di disk.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white60,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Error Message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFF5252),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x4DFF5252)),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Input Master Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(color: Colors.white),
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: 'Master Password',
                        labelStyle: const TextStyle(color: Colors.white60),
                        prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.white60),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.white60,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF18181F),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Input Confirm Password (Only in create flow)
                    if (!_hasMasterPassword) ...[
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        style: GoogleFonts.inter(color: Colors.white),
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Master Password',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.lock_person_outlined, color: Colors.white60),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white60,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF18181F),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password tidak boleh kosong';
                          }
                          if (value != _passwordController.text) {
                            return 'Password tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shadowColor: const Color(0x4D8B5CF6),
                        elevation: 5,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _hasMasterPassword ? 'Masuk' : 'Buat Password',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Offline badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 14,
                          color: const Color(0x66FFFFFF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '100% Offline & Lokal',
                          style: GoogleFonts.inter(
                            color: const Color(0x66FFFFFF),
                            fontSize: 12,
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
      ),
    );
  }
}
