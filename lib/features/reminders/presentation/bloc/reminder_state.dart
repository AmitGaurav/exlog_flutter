import 'package:equatable/equatable.dart';

import '../../domain/entities/reminder.dart';

enum ReminderStatus { initial, loading, success, failure }

class ReminderState extends Equatable {
  final ReminderStatus status;
  final List<Reminder> reminders;
  final String? error;
  final String? successMessage;

  const ReminderState({
    this.status = ReminderStatus.initial,
    this.reminders = const [],
    this.error,
    this.successMessage,
  });

  List<Reminder> get upcomingReminders {
    final list = reminders.where((r) => !r.isPaid).toList();
    list.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return list;
  }

  List<Reminder> get overdueReminders {
    final list = reminders.where((r) => r.isOverdue).toList();
    list.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return list;
  }

  List<Reminder> get paidReminders {
    final list = reminders.where((r) => r.isPaid).toList();
    list.sort((a, b) => (b.lastPaidDate ?? b.updatedAt).compareTo(a.lastPaidDate ?? a.updatedAt));
    return list;
  }

  ReminderState copyWith({
    ReminderStatus? status,
    List<Reminder>? reminders,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) =>
      ReminderState(
        status: status ?? this.status,
        reminders: reminders ?? this.reminders,
        error: clearError ? null : (error ?? this.error),
        successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      );

  @override
  List<Object?> get props => [status, reminders, error, successMessage];
}
