import 'package:equatable/equatable.dart';

import '../../domain/entities/reminder.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

class ReminderLoadRequested extends ReminderEvent {
  const ReminderLoadRequested();
}

class ReminderAddRequested extends ReminderEvent {
  final Reminder reminder;

  const ReminderAddRequested(this.reminder);

  @override
  List<Object?> get props => [reminder];
}

class ReminderDeleteRequested extends ReminderEvent {
  final String reminderId;

  const ReminderDeleteRequested(this.reminderId);

  @override
  List<Object?> get props => [reminderId];
}

class ReminderMarkAsPaidRequested extends ReminderEvent {
  final Reminder reminder;

  const ReminderMarkAsPaidRequested(this.reminder);

  @override
  List<Object?> get props => [reminder];
}

class ReminderUndoPaymentRequested extends ReminderEvent {
  final Reminder reminder;

  const ReminderUndoPaymentRequested(this.reminder);

  @override
  List<Object?> get props => [reminder];
}

class ReminderErrorCleared extends ReminderEvent {
  const ReminderErrorCleared();
}

class ReminderSuccessCleared extends ReminderEvent {
  const ReminderSuccessCleared();
}
