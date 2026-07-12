import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Icon name → IconData for the Transaction Types icon picker, mirroring
/// iOS's IconPickerView SF Symbol grid with Material equivalents.
const Map<String, IconData> kTransactionTypeIcons = {
  'circle.fill': Icons.circle,
  'square.fill': Icons.square,
  'star.fill': Icons.star,
  'heart.fill': Icons.favorite,
  'flag.fill': Icons.flag,
  'bookmark.fill': Icons.bookmark,
  'bag.fill': Icons.shopping_bag,
  'cart.fill': Icons.shopping_cart,
  'creditcard.fill': Icons.credit_card,
  'dollarsign.circle.fill': Icons.attach_money,
  'house.fill': Icons.home,
  'car.fill': Icons.directions_car,
  'airplane': Icons.flight,
  'fork.knife': Icons.restaurant,
  'cup.and.saucer.fill': Icons.coffee,
  'tshirt.fill': Icons.checkroom,
  'gamecontroller.fill': Icons.sports_esports,
  'book.fill': Icons.menu_book,
  'briefcase.fill': Icons.work,
  'wrench.and.screwdriver.fill': Icons.build,
  'cross.fill': Icons.medical_services,
  'leaf.fill': Icons.eco,
  'arrow.up.circle.fill': Icons.arrow_circle_up,
  'arrow.down.circle.fill': Icons.arrow_circle_down,
  'arrow.left.arrow.right.circle.fill': Icons.swap_horiz,
  'banknote.fill': Icons.payments,
  'building.columns.fill': Icons.account_balance,
  'chart.line.uptrend.xyaxis': Icons.trending_up,
};

const String kDefaultTransactionTypeIcon = 'circle.fill';

class TransactionTypeModel extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final String displayName;
  final String icon;
  final String colorHex;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionTypeModel({
    this.id,
    required this.userId,
    required this.name,
    required this.displayName,
    this.icon = kDefaultTransactionTypeIcon,
    this.colorHex = '#007AFF',
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 99,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionTypeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TransactionTypeModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      icon: data['icon'] as String? ?? kDefaultTransactionTypeIcon,
      colorHex: data['colorHex'] as String? ?? '#007AFF',
      isDefault: data['isDefault'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 99,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'displayName': displayName,
        'icon': icon,
        'colorHex': colorHex,
        'isDefault': isDefault,
        'isActive': isActive,
        'sortOrder': sortOrder,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// The 4 defaults matching the existing fixed `TransactionType` enum
  /// (lib/features/transactions/domain/entities/transaction.dart) so this
  /// Settings screen shows familiar entries the first time it's opened.
  static List<TransactionTypeModel> defaults(String userId) {
    final now = DateTime.now();
    TransactionTypeModel def(String name, String displayName, String icon, String color, int order) =>
        TransactionTypeModel(
          userId: userId,
          name: name,
          displayName: displayName,
          icon: icon,
          colorHex: color,
          isDefault: true,
          sortOrder: order,
          createdAt: now,
          updatedAt: now,
        );
    return [
      def('expense', 'Expense', 'arrow.up.circle.fill', '#FF3B30', 1),
      def('credit', 'Credit', 'arrow.down.circle.fill', '#34C759', 2),
      def('cash_withdrawal', 'Cash Withdrawal', 'banknote.fill', '#FF9500', 3),
      def('self_transfer', 'Self Transfer', 'arrow.left.arrow.right.circle.fill', '#5856D6', 4),
    ];
  }

  TransactionTypeModel copyWith({
    String? id,
    String? name,
    String? displayName,
    String? icon,
    String? colorHex,
    bool? isActive,
    int? sortOrder,
    DateTime? updatedAt,
  }) =>
      TransactionTypeModel(
        id: id ?? this.id,
        userId: userId,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        icon: icon ?? this.icon,
        colorHex: colorHex ?? this.colorHex,
        isDefault: isDefault,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, userId, name, displayName, icon, colorHex, isDefault, isActive, sortOrder, createdAt, updatedAt];
}
