import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum BucketType {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly;

  String get displayName => '${name[0].toUpperCase()}${name.substring(1)}';

  int get sortOrder {
    switch (this) {
      case daily:
        return 0;
      case weekly:
        return 1;
      case monthly:
        return 2;
      case quarterly:
        return 3;
      case yearly:
        return 4;
    }
  }

  IconData get icon {
    switch (this) {
      case daily:
        return Icons.wb_sunny_outlined;
      case weekly:
        return Icons.calendar_today;
      case monthly:
        return Icons.calendar_month;
      case quarterly:
        return Icons.calendar_view_month_outlined;
      case yearly:
        return Icons.event;
    }
  }

  static BucketType fromString(String value) => BucketType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => BucketType.monthly,
      );
}

// Maps iOS SF Symbol names to Material Icons so DB stays iOS-compatible.
const Map<String, IconData> kCategoryIcons = {
  'tag.fill': Icons.label,
  'cart.fill': Icons.shopping_cart,
  'fork.knife': Icons.restaurant,
  'car.fill': Icons.directions_car,
  'house.fill': Icons.home,
  'flame.fill': Icons.local_fire_department,
  'cross.case.fill': Icons.medical_services,
  'person.fill': Icons.person,
  'wifi': Icons.wifi,
  'tv.fill': Icons.tv,
  'bolt.fill': Icons.bolt,
  'airplane': Icons.flight,
  'book.fill': Icons.book,
  'tshirt.fill': Icons.checkroom,
  'building.2.fill': Icons.apartment,
  'ellipsis.circle.fill': Icons.more_horiz,
  'local_gas_station': Icons.local_gas_station,
  'fitness_center': Icons.fitness_center,
};

const String kDefaultIconName = 'tag.fill';

const List<Color> kCategoryColors = [
  Color(0xFF4CAF50),
  Color(0xFFFF9800),
  Color(0xFF2196F3),
  Color(0xFFF44336),
  Color(0xFF9C27B0),
  Color(0xFFFF5722),
  Color(0xFF00BCD4),
  Color(0xFF3F51B5),
  Color(0xFF795548),
  Color(0xFF607D8B),
  Color(0xFFE91E63),
  Color(0xFF8BC34A),
  Color(0xFF9E9E9E),
  Color(0xFF007AFF),
  Color(0xFFFFEB3B),
  Color(0xFF000000),
];

IconData iconDataFromName(String? name) =>
    kCategoryIcons[name] ?? Icons.label;

Color colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF007AFF);
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

String colorToHex(Color color) {
  return '#${color.r.toInt().toRadixString(16).padLeft(2, '0')}'
      '${color.g.toInt().toRadixString(16).padLeft(2, '0')}'
      '${color.b.toInt().toRadixString(16).padLeft(2, '0')}';
}

class Category extends Equatable {
  final String? id;
  final String name;
  final BucketType bucket;
  final bool requiresComment;
  final bool isActive;
  final String userId;
  final String? iconName;
  final String? colorHex;
  final int? sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    this.id,
    required this.name,
    required this.bucket,
    this.requiresComment = false,
    this.isActive = true,
    required this.userId,
    this.iconName,
    this.colorHex,
    this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.create({
    required String name,
    required BucketType bucket,
    bool requiresComment = false,
    required String userId,
    String? iconName,
    String? colorHex,
  }) {
    final now = DateTime.now();
    return Category(
      name: name,
      bucket: bucket,
      requiresComment: requiresComment,
      isActive: true,
      userId: userId,
      iconName: iconName,
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Category.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Category(
      id: doc.id,
      name: data['name'] as String? ?? '',
      bucket: BucketType.fromString(data['bucket'] as String? ?? 'monthly'),
      requiresComment: data['requiresComment'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      userId: data['userId'] as String? ?? '',
      iconName: data['iconName'] as String?,
      colorHex: data['colorHex'] as String?,
      sortOrder: data['sortOrder'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'bucket': bucket.name,
        'requiresComment': requiresComment,
        'isActive': isActive,
        'userId': userId,
        'iconName': iconName,
        'colorHex': colorHex,
        'sortOrder': sortOrder,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  Category copyWith({
    String? id,
    String? name,
    BucketType? bucket,
    bool? requiresComment,
    bool? isActive,
    String? userId,
    String? iconName,
    String? colorHex,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        bucket: bucket ?? this.bucket,
        requiresComment: requiresComment ?? this.requiresComment,
        isActive: isActive ?? this.isActive,
        userId: userId ?? this.userId,
        iconName: iconName ?? this.iconName,
        colorHex: colorHex ?? this.colorHex,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id, name, bucket, requiresComment, isActive, userId,
        iconName, colorHex, sortOrder, createdAt, updatedAt,
      ];
}
