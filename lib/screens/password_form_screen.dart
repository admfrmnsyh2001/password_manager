import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/folder_model.dart';
import '../models/password_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class PasswordFormScreen extends StatefulWidget {
  final Folder folder;
  final String masterPassword;
  final Password? passwordToEdit;

  const PasswordFormScreen({
    super.key,
    required this.folder,
    required this.masterPassword,
    this.passwordToEdit,
  });

  @override
  State<PasswordFormScreen> createState() => _PasswordFormScreenState();
}

class _PasswordFormScreenState extends State<PasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.passwordToEdit != null) {
      _titleController.text = widget.passwordToEdit!.title;
      _usernameController.text = widget.passwordToEdit!.username;
      _notesController.text = widget.passwordToEdit!.notes;
      try {
        _passwordController.text = EncryptionService.decrypt(
          widget.passwordToEdit!.passwordEncrypted,
          widget.masterPassword,
        );
      } catch (e) {
        _passwordController.text = '';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateSecurePassword({int length = 16}) {
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,./<>?';
    final allChars = '$lower$upper$numbers$symbols';
    
    final rand = Random.secure();
    return List.generate(length, (index) => allChars[rand.nextInt(allChars.length)]).join('');
  }

  void _onGeneratePressed() {
    final password = _generateSecurePassword();
    setState(() {
      _passwordController.text = password;
      _obscurePassword = false; // Show so the user sees what was generated
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final title = _titleController.text.trim();
    final username = _usernameController.text.trim();
    final plainPassword = _passwordController.text;
    final notes = _notesController.text.trim();

    try {
      final encryptedPassword = EncryptionService.encrypt(plainPassword, widget.masterPassword);

      if (widget.passwordToEdit == null) {
        // Create
        final newPassword = Password(
          folderId: widget.folder.id!,
          title: title,
          username: username,
          passwordEncrypted: encryptedPassword,
          notes: notes,
          createdAt: DateTime.now(),
        );
        await DatabaseService.instance.createPassword(newPassword);
      } else {
        // Edit
        final updatedPassword = Password(
          id: widget.passwordToEdit!.id,
          folderId: widget.passwordToEdit!.folderId,
          title: title,
          username: username,
          passwordEncrypted: encryptedPassword,
          notes: notes,
          createdAt: widget.passwordToEdit!.createdAt,
        );
        await DatabaseService.instance.updatePassword(updatedPassword);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate data changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e')),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.passwordToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Sandi' : 'Tambah Sandi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6))),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Color(0xFF8B5CF6), size: 28),
              onPressed: _handleSave,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Judul / Nama Akun',
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.title_rounded, color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF1E1E24),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),

              // Username/Email Field
              TextFormField(
                controller: _usernameController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username / Email',
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF1E1E24),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field with Generator option
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white60),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white60,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
                        tooltip: 'Generate Sandi Acak',
                        onPressed: _onGeneratePressed,
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E24),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Password tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),

              // Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.notes_rounded, color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF1E1E24),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
