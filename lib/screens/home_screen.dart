import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/folder_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'folder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Folder> _folders = [];
  Map<int, int> _passwordCounts = {};
  bool _isLoading = true;

  // Preset of icons that the user can choose from for folders
  final Map<String, IconData> _iconMap = {
    'work': Icons.work_rounded,
    'personal': Icons.person_rounded,
    'social': Icons.share_rounded,
    'finance': Icons.account_balance_wallet_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'key': Icons.vpn_key_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final folders = await DatabaseService.instance.getFolders();
      final Map<int, int> counts = {};

      for (var folder in folders) {
        if (folder.id != null) {
          final passwords = await DatabaseService.instance.getPasswordsByFolder(folder.id!);
          counts[folder.id!] = passwords.length;
        }
      }

      setState(() {
        _folders = folders;
        _passwordCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  Future<void> _deleteFolder(int folderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('Hapus Folder?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Menghapus folder ini juga akan menghapus seluruh data password di dalamnya secara permanen.', style: GoogleFonts.inter(color: Colors.white70)),
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
      await DatabaseService.instance.deleteFolder(folderId);
      _loadData();
    }
  }

  void _showFolderDialog({Folder? folder}) {
    final nameController = TextEditingController(text: folder?.name ?? '');
    String selectedIconKey = folder?.icon ?? 'key';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                folder == null ? 'Tambah Folder' : 'Edit Folder',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nama Folder',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF14141A),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Pilih Icon:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _iconMap.entries.map((entry) {
                        final isSelected = selectedIconKey == entry.key;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIconKey = entry.key;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF14141A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : const Color(0x0DFFFFFF),
                              ),
                            ),
                            child: Icon(
                              entry.value,
                              color: isSelected ? Colors.white : Colors.white70,
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    if (folder == null) {
                      // Create
                      final newFolder = Folder(
                        name: name,
                        icon: selectedIconKey,
                        createdAt: DateTime.now(),
                      );
                      await DatabaseService.instance.createFolder(newFolder);
                    } else {
                      // Update
                      final updatedFolder = Folder(
                        id: folder.id,
                        name: name,
                        icon: selectedIconKey,
                        createdAt: folder.createdAt,
                      );
                      await DatabaseService.instance.updateFolder(updatedFolder);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadData();
                    }
                  },
                  child: Text(folder == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        title: Text(
          'Vault Saya',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Kunci Vault',
            onPressed: () {
              AuthService.instance.clearSession();
              // Navigate back to login
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
            )
          : _folders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 80, color: const Color(0x19FFFFFF)),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada folder',
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ketuk + untuk membuat folder baru.',
                        style: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    final count = _passwordCounts[folder.id] ?? 0;
                    final iconData = _iconMap[folder.icon] ?? Icons.folder_rounded;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Slidable(
                        key: ValueKey(folder.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.5,
                          children: [
                            SlidableAction(
                              onPressed: (context) => _showFolderDialog(folder: folder),
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
                              onPressed: (context) => _deleteFolder(folder.id!),
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
                              child: Icon(
                                iconData,
                                color: const Color(0xFF8B5CF6),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              folder.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '$count Item Sandi',
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
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FolderScreen(
                                    folder: folder,
                                    masterPassword: AuthService.instance.activeMasterPassword ?? '',
                                  ),
                                ),
                              ).then((_) => _loadData()); // Reload on back
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFolderDialog(),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
