import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/folder_model.dart';
import '../models/password_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';
import 'password_form_screen.dart';

class DetailScreen extends StatefulWidget {
  final Folder folder;
  final Password password;
  final String masterPassword;

  const DetailScreen({
    super.key,
    required this.folder,
    required this.password,
    required this.masterPassword,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Password _password;
  String _decryptedPassword = '';
  bool _obscurePassword = true;
  bool _decryptionError = false;

  @override
  void initState() {
    super.initState();
    _password = widget.password;
    _decrypt();
  }

  void _decrypt() {
    try {
      final decrypted = EncryptionService.decrypt(
        _password.passwordEncrypted,
        widget.masterPassword,
      );
      setState(() {
        _decryptedPassword = decrypted;
        _decryptionError = false;
      });
    } catch (e) {
      setState(() {
        _decryptedPassword = 'Gagal mendekripsi kata sandi';
        _decryptionError = true;
      });
    }
  }

  Future<void> _deletePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('Hapus Sandi?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus akun/sandi ini secara permanen?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.deletePassword(_password.id!);
      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger reload on folder screen
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disalin!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        title: Text(
          'Detail Sandi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white70),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PasswordFormScreen(
                    folder: widget.folder,
                    masterPassword: widget.masterPassword,
                    passwordToEdit: _password,
                  ),
                ),
              );

              if (result == true) {
                final updated = await DatabaseService.instance.getPassword(_password.id!);
                if (updated != null && mounted) {
                  setState(() {
                    _password = updated;
                    _decrypt();
                  });
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _deletePassword,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x0DFFFFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 14, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Text(
                        widget.folder.name,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x0DFFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('JUDUL / NAMA AKUN', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(_password.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(color: Color(0x0DFFFFFF), height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('USERNAME / EMAIL', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 6),
                          Text(_password.username, style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF8B5CF6)),
                        onPressed: () => _copyToClipboard(_password.username),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0x0DFFFFFF), height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('KATA SANDI', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const SizedBox(height: 6),
                            Text(
                              _obscurePassword
                                  ? '••••••••••••'
                                  : _decryptedPassword,
                              style: GoogleFonts.inter(
                                color: _decryptionError ? Colors.redAccent : Colors.white,
                                fontSize: 16,
                                letterSpacing: _obscurePassword ? 2.0 : 0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_decryptionError)
                            IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white60,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: Color(0xFF8B5CF6)),
                            onPressed: _decryptionError
                                ? null
                                : () => _copyToClipboard(_decryptedPassword),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Color(0x0DFFFFFF), height: 32),
                  Text('CATATAN', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(
                    _password.notes.isEmpty ? 'Tidak ada catatan.' : _password.notes,
                    style: GoogleFonts.inter(
                      color: _password.notes.isEmpty ? Colors.white24 : Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
