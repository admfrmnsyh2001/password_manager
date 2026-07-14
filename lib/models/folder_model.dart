class Folder {
  final int? id;
  final int? parentId;
  final String name;
  final String icon;
  final DateTime createdAt;

  Folder({
    this.id,
    this.parentId,
    required this.name,
    required this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'parent_id': parentId,
      'name': name,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      parentId: map['parent_id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
