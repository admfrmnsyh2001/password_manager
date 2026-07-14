import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/folder_model.dart';
import '../models/password_model.dart';
import '../services/database_service.dart';
import 'detail_screen.dart';
import 'password_form_screen.dart';

class FolderScreen extends StatefulWidget {
  final Folder folder;
  final String masterPassword;

  const FolderScreen({
    super.key,
    required this.folder,
    required this.masterPassword,
  });

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<Password> _passwords = [];
  List<Password> _filteredPasswords = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPasswords();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPasswords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final passwords = await DatabaseService.instance.getPasswordsByFolder(widget.folder.id!);
      setState(() {
        _passwords = passwords;
        _filteredPasswords = passwords;
        _isLoading = false;
      });
      _onSearchChanged(); // Re-apply search filter
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat sandi: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredPasswords = _passwords;
      } else {
        _filteredPasswords = _passwords.where((password) {
          return password.title.toLowerCase().contains(query) ||
              password.username.toLowerCase().contains(query) ||
              password.notes.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deletePassword(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('Hapus Sandi?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus sandi ini?', style: GoogleFonts.inter(color: Colors.white70)),
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
      await DatabaseService.instance.deletePassword(id);
      _loadPasswords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        title: Text(
          widget.folder.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari sandi di folder ini...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
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
          ),

          // Main content list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    ),
                  )
                : _filteredPasswords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: Color(0x19FFFFFF),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Sandi tidak ditemukan'
                                  : 'Belum ada sandi di folder ini',
                              style: GoogleFonts.inter(color: Colors.white60, fontSize: 16),
                            ),
                            if (_searchController.text.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Ketuk + di kanan bawah untuk menambahkan.',
                                style: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                              ),
                            ]
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: _filteredPasswords.length,
                        itemBuilder: (context, index) {
                          final password = _filteredPasswords[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Slidable(
                              key: ValueKey(password.id),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                extentRatio: 0.5,
                                children: [
                                  SlidableAction(
                                    onPressed: (context) async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PasswordFormScreen(
                                            folder: widget.folder,
                                            masterPassword: widget.masterPassword,
                                            passwordToEdit: password,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadPasswords();
                                      }
                                    },
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: const Color(0xFF60A5FA),
                                    icon: Icons.edit_rounded,
                                    label: 'Edit',
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                  SlidableAction(
                                    onPressed: (context) => _deletePassword(password.id!),
                                    backgroundColor: const Color(0xFF7F1D1D),
                                    foregroundColor: const Color(0xFFFCA5A5),
                                    icon: Icons.delete_rounded,
                                    label: 'Hapus',
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E24),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0x0DFFFFFF)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF14141A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.vpn_key_rounded,
                                      color: Color(0xFF8B5CF6),
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    password.title,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      password.username,
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white24,
                                    size: 14,
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailScreen(
                                          folder: widget.folder,
                                          password: password,
                                          masterPassword: widget.masterPassword,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadPasswords();
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PasswordFormScreen(
                folder: widget.folder,
                masterPassword: widget.masterPassword,
              ),
            ),
          );
          if (result == true) {
            _loadPasswords();
          }
        },
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
