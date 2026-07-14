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
  late String _currentFolderName;
  List<Password> _passwords = [];
  List<Password> _filteredPasswords = [];
  List<Folder> _subfolders = [];
  List<Folder> _filteredSubfolders = [];
  Map<int, int> _subfolderCounts = {};
  bool _isLoading = true;
  final _searchController = TextEditingController();

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
    _currentFolderName = widget.folder.name;
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final passwords = await DatabaseService.instance.getPasswordsByFolder(widget.folder.id!);
      final subfolders = await DatabaseService.instance.getFolders(parentId: widget.folder.id!);
      
      final Map<int, int> counts = {};
      for (var sub in subfolders) {
        if (sub.id != null) {
          final subPasswords = await DatabaseService.instance.getPasswordsByFolder(sub.id!);
          counts[sub.id!] = subPasswords.length;
        }
      }

      setState(() {
        _passwords = passwords;
        _filteredPasswords = passwords;
        _subfolders = subfolders;
        _filteredSubfolders = subfolders;
        _subfolderCounts = counts;
        _isLoading = false;
      });
      _onSearchChanged(); // Re-apply search filter
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredPasswords = _passwords;
        _filteredSubfolders = _subfolders;
      } else {
        _filteredPasswords = _passwords.where((password) {
          return password.title.toLowerCase().contains(query) ||
              password.username.toLowerCase().contains(query) ||
              password.notes.toLowerCase().contains(query);
        }).toList();

        _filteredSubfolders = _subfolders.where((sub) {
          return sub.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteSubfolder(int folderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('Hapus Subfolder?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Menghapus subfolder ini juga akan menghapus seluruh data password di dalamnya secara permanen.', style: GoogleFonts.inter(color: Colors.white70)),
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

  void _showSubfolderDialog({Folder? folder}) {
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
                folder == null ? 'Tambah Subfolder' : 'Edit Subfolder',
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
                        labelText: 'Nama Subfolder',
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
                      // Create subfolder
                      final newFolder = Folder(
                        parentId: widget.folder.id,
                        name: name,
                        icon: selectedIconKey,
                        createdAt: DateTime.now(),
                      );
                      await DatabaseService.instance.createFolder(newFolder);
                    } else {
                      // Update subfolder
                      final updatedFolder = Folder(
                        id: folder.id,
                        parentId: folder.parentId,
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
      _loadData();
    }
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.vpn_key_rounded, color: Color(0xFF8B5CF6)),
                title: Text('Tambah Sandi', style: GoogleFonts.inter(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
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
                    _loadData();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_rounded, color: Color(0xFF8B5CF6)),
                title: Text('Tambah Subfolder', style: GoogleFonts.inter(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSubfolderDialog();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildListItems() {
    final listItems = <Widget>[];

    // Render Subfolders Section
    if (_filteredSubfolders.isNotEmpty) {
      listItems.add(
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
          child: Text(
            'SUBFOLDER',
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );

      for (var sub in _filteredSubfolders) {
        final count = _subfolderCounts[sub.id] ?? 0;
        final iconData = _iconMap[sub.icon] ?? Icons.folder_rounded;

        listItems.add(
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Slidable(
              key: ValueKey('sub_${sub.id}'),
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.5,
                children: [
                  SlidableAction(
                    onPressed: (context) => _showSubfolderDialog(folder: sub),
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
                    onPressed: (context) => _deleteSubfolder(sub.id!),
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
                    sub.name,
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
                          folder: sub,
                          masterPassword: widget.masterPassword,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                ),
              ),
            ),
          ),
        );
      }
    }

    // Render Passwords Section
    if (_filteredPasswords.isNotEmpty) {
      listItems.add(
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
          child: Text(
            'ITEM SANDI',
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );

      for (var password in _filteredPasswords) {
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Slidable(
              key: ValueKey('pass_${password.id}'),
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
                        _loadData();
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
                      _loadData();
                    }
                  },
                ),
              ),
            ),
          ),
        );
      }
    }

    return listItems;
  }

  Future<void> _deleteCurrentFolder() async {
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
      await DatabaseService.instance.deleteFolder(widget.folder.id!);
      if (mounted) {
        Navigator.pop(context, true); // Pop back to parent with reload trigger
      }
    }
  }

  void _showEditCurrentFolderDialog() {
    final nameController = TextEditingController(text: _currentFolderName);
    String selectedIconKey = widget.folder.icon;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Edit Folder',
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

                    final updatedFolder = Folder(
                      id: widget.folder.id,
                      parentId: widget.folder.parentId,
                      name: name,
                      icon: selectedIconKey,
                      createdAt: widget.folder.createdAt,
                    );
                    final navigator = Navigator.of(context);
                    await DatabaseService.instance.updateFolder(updatedFolder);

                    if (mounted) {
                      setState(() {
                        _currentFolderName = name;
                      });
                      navigator.pop();
                    }
                  },
                  child: const Text('Simpan'),
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
    final listWidgets = _buildListItems();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        title: Text(
          _currentFolderName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: const Color(0xFF1E1E24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditCurrentFolderDialog();
              } else if (value == 'delete') {
                _deleteCurrentFolder();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text('Edit Folder', style: GoogleFonts.inter(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Text('Hapus Folder', style: GoogleFonts.inter(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                hintText: 'Cari sandi atau folder...',
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

          // Main list content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    ),
                  )
                : listWidgets.isEmpty
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
                                  ? 'Item tidak ditemukan'
                                  : 'Belum ada isi di folder ini',
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
                    : ListView(
                        children: listWidgets,
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
