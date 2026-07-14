class Password {
  final int? id;
  final int folderId;
  final String title;
  final String username;
  final String passwordEncrypted;
  final String notes;
  final DateTime createdAt;

  Password({
    this.id,
    required this.folderId,
    required this.title,
    required this.username,
    required this.passwordEncrypted,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'folder_id': folderId,
      'title': title,
      'username': username,
      'password_encrypted': passwordEncrypted,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Password.fromMap(Map<String, dynamic> map) {
    return Password(
      id: map['id'] as int?,
      folderId: map['folder_id'] as int,
      title: map['title'] as String,
      username: map['username'] as String,
      passwordEncrypted: map['password_encrypted'] as String,
      notes: map['notes'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
