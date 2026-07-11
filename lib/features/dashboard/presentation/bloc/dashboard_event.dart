import 'package:equatable/equatable.dart';

enum DashboardTab { thisMonth, thisYear, analytics }

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

class DashboardTabChanged extends DashboardEvent {
  final DashboardTab tab;
  const DashboardTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}
