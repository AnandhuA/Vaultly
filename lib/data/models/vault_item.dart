enum VaultItemType {
  link,
  instagram,
  linkedin,
  youtube,
  pdf,
  image,
  video,
  note,
  text,
  document,
  voice,
  screenshot,
}

class VaultItem {
  VaultItem({
    required this.id,
    required this.title,
    this.description = '',
    this.originalUrl,
    required this.sourceApp,
    required this.itemType,
    this.collectionId,
    this.tags = const [],
    this.userNote = '',
    this.thumbnailPath,
    this.localFilePath,
    required this.createdAt,
    required this.updatedAt,
    this.reminderDate,
    this.isFavorite = false,
    this.isArchived = false,
    this.isReadLater = true,
    this.needsReview = false,
    this.confidence = 1,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String description;
  final String? originalUrl;
  final String sourceApp;
  final VaultItemType itemType;
  final String? collectionId;
  final List<String> tags;
  final String userNote;
  final String? thumbnailPath;
  final String? localFilePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reminderDate;
  final bool isFavorite;
  final bool isArchived;
  final bool isReadLater;
  final bool needsReview;
  final double confidence;
  final Map<String, dynamic> metadata;

  VaultItem copyWith({
    String? title,
    String? description,
    String? originalUrl,
    String? sourceApp,
    VaultItemType? itemType,
    String? collectionId,
    List<String>? tags,
    String? userNote,
    String? thumbnailPath,
    String? localFilePath,
    DateTime? updatedAt,
    DateTime? reminderDate,
    bool clearReminder = false,
    bool? isFavorite,
    bool? isArchived,
    bool? isReadLater,
    bool? needsReview,
    double? confidence,
    Map<String, dynamic>? metadata,
    bool clearCollection = false,
  }) {
    return VaultItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      originalUrl: originalUrl ?? this.originalUrl,
      sourceApp: sourceApp ?? this.sourceApp,
      itemType: itemType ?? this.itemType,
      collectionId: clearCollection ? null : collectionId ?? this.collectionId,
      tags: tags ?? this.tags,
      userNote: userNote ?? this.userNote,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      localFilePath: localFilePath ?? this.localFilePath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      reminderDate: clearReminder ? null : reminderDate ?? this.reminderDate,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isReadLater: isReadLater ?? this.isReadLater,
      needsReview: needsReview ?? this.needsReview,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'originalUrl': originalUrl,
        'sourceApp': sourceApp,
        'itemType': itemType.name,
        'collectionId': collectionId,
        'tags': tags,
        'userNote': userNote,
        'thumbnailPath': thumbnailPath,
        'localFilePath': localFilePath,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'reminderDate': reminderDate?.toIso8601String(),
        'isFavorite': isFavorite,
        'isArchived': isArchived,
        'isReadLater': isReadLater,
        'needsReview': needsReview,
        'confidence': confidence,
        'metadata': metadata,
      };

  factory VaultItem.fromMap(Map<dynamic, dynamic> map) {
    return VaultItem(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Untitled',
      description: map['description'] as String? ?? '',
      originalUrl: map['originalUrl'] as String?,
      sourceApp: map['sourceApp'] as String? ?? 'Vaultly',
      itemType: VaultItemType.values.firstWhere(
        (type) => type.name == map['itemType'],
        orElse: () => VaultItemType.link,
      ),
      collectionId: map['collectionId'] as String?,
      tags: List<String>.from(map['tags'] as List? ?? const []),
      userNote: map['userNote'] as String? ?? '',
      thumbnailPath: map['thumbnailPath'] as String?,
      localFilePath: map['localFilePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      reminderDate: map['reminderDate'] == null
          ? null
          : DateTime.parse(map['reminderDate'] as String),
      isFavorite: map['isFavorite'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      isReadLater: map['isReadLater'] as bool? ?? true,
      needsReview: map['needsReview'] as bool? ?? map['collectionId'] == null,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }
}
