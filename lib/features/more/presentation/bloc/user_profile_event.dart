import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile.dart';

abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

class UserProfileLoadRequested extends UserProfileEvent {
  const UserProfileLoadRequested();
}

class UserProfileCurrencyChanged extends UserProfileEvent {
  final String currencyCode;
  const UserProfileCurrencyChanged(this.currencyCode);

  @override
  List<Object?> get props => [currencyCode];
}

class UserProfileAIParserConfigChanged extends UserProfileEvent {
  final AIParserConfig config;
  const UserProfileAIParserConfigChanged(this.config);

  @override
  List<Object?> get props => [config];
}

class UserProfileSelfNamesChanged extends UserProfileEvent {
  final List<String> selfNames;
  const UserProfileSelfNamesChanged(this.selfNames);

  @override
  List<Object?> get props => [selfNames];
}
