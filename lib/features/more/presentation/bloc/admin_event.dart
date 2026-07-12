import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class AdminLoadRequested extends AdminEvent {
  const AdminLoadRequested();
}

class AdminUserSearchChanged extends AdminEvent {
  final String query;
  const AdminUserSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class AdminToggleUserActiveRequested extends AdminEvent {
  final String uid;
  final bool isActive;
  const AdminToggleUserActiveRequested({required this.uid, required this.isActive});

  @override
  List<Object?> get props => [uid, isActive];
}

class AdminSetPremiumTierRequested extends AdminEvent {
  final String uid;
  final PremiumTier tier;
  const AdminSetPremiumTierRequested({required this.uid, required this.tier});

  @override
  List<Object?> get props => [uid, tier];
}
