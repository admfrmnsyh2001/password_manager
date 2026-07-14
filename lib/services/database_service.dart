import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/folder_model.dart';
import '../models/password_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('password_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE passwords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        username TEXT NOT NULL,
        password_encrypted TEXT NOT NULL,
        notes TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Folder CRUD ---

  Future<int> createFolder(Folder folder) async {
    final db = await instance.database;
    return await db.insert('folders', folder.toMap());
  }

  Future<Folder?> getFolder(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Folder.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Folder>> getFolders() async {
    final db = await instance.database;
    final result = await db.query('folders', orderBy: 'name ASC');
    return result.map((json) => Folder.fromMap(json)).toList();
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await instance.database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await instance.database;
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Password CRUD ---

  Future<int> createPassword(Password password) async {
    final db = await instance.database;
    return await db.insert('passwords', password.toMap());
  }

  Future<Password?> getPassword(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Password.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Password>> getPasswords() async {
    final db = await instance.database;
    final result = await db.query('passwords', orderBy: 'title ASC');
    return result.map((json) => Password.fromMap(json)).toList();
  }

  Future<List<Password>> getPasswordsByFolder(int folderId) async {
    final db = await instance.database;
    final result = await db.query(
      'passwords',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'title ASC',
    );
    return result.map((json) => Password.fromMap(json)).toList();
  }

  Future<int> updatePassword(Password password) async {
    final db = await instance.database;
    return await db.update(
      'passwords',
      password.toMap(),
      where: 'id = ?',
      whereArgs: [password.id],
    );
  }

  Future<int> deletePassword(int id) async {
    final db = await instance.database;
    return await db.delete(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
