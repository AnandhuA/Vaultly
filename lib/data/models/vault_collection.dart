class VaultCollection {
  VaultCollection({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.itemCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  final String id;
  final String name;
  final String icon;
  final int color;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  VaultCollection copyWith({
    String? name,
    String? icon,
    int? color,
    int? itemCount,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return VaultCollection(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'itemCount': itemCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isPinned': isPinned,
      };

  factory VaultCollection.fromMap(Map<dynamic, dynamic> map) {
    return VaultCollection(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? 'folder',
      color: map['color'] as int? ?? 0xFF4F46E5,
      itemCount: map['itemCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }
}
