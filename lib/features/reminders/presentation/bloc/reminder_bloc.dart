import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/reminder_repository.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final ReminderRepository _repository;

  ReminderBloc(this._repository) : super(const ReminderState()) {
    on<ReminderLoadRequested>(_onLoad);
    on<ReminderAddRequested>(_onAdd);
    on<ReminderDeleteRequested>(_onDelete);
    on<ReminderMarkAsPaidRequested>(_onMarkAsPaid);
    on<ReminderUndoPaymentRequested>(_onUndoPayment);
    on<ReminderErrorCleared>(_onErrorCleared);
    on<ReminderSuccessCleared>(_onSuccessCleared);
  }

  Future<void> _onLoad(
    ReminderLoadRequested event,
    Emitter<ReminderState> emit,
  ) async {
    emit(state.copyWith(status: ReminderStatus.loading, clearError: true));
    try {
      final reminders = await _repository.getReminders();
      emit(state.copyWith(status: ReminderStatus.success, reminders: reminders));
    } catch (_) {
      emit(state.copyWith(
        status: ReminderStatus.failure,
        error: 'Failed to load reminders.',
      ));
    }
  }

  Future<void> _onAdd(
    ReminderAddRequested event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      final id = await _repository.createReminder(event.reminder);
      final saved = event.reminder.copyWith(id: id);
      final updated = List.of(state.reminders)..add(saved);
      emit(state.copyWith(
        status: ReminderStatus.success,
        reminders: updated,
        successMessage: 'Reminder created successfully',
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to create reminder.'));
    }
  }

  Future<void> _onDelete(
    ReminderDeleteRequested event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await _repository.deleteReminder(event.reminderId);
      final updated = state.reminders.where((r) => r.id != event.reminderId).toList();
      emit(state.copyWith(
        status: ReminderStatus.success,
        reminders: updated,
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to delete reminder.'));
    }
  }

  Future<void> _onMarkAsPaid(
    ReminderMarkAsPaidRequested event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      final updatedReminder = event.reminder.markedAsPaid();
      await _repository.updateReminder(updatedReminder);
      final updated = state.reminders
          .map((r) => r.id == updatedReminder.id ? updatedReminder : r)
          .toList();
      emit(state.copyWith(
        status: ReminderStatus.success,
        reminders: updated,
        successMessage: "'${event.reminder.title}' marked as paid",
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to mark reminder as paid.'));
    }
  }

  Future<void> _onUndoPayment(
    ReminderUndoPaymentRequested event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      final updatedReminder = event.reminder.paymentUndone();
      await _repository.updateReminder(updatedReminder);
      final updated = state.reminders
          .map((r) => r.id == updatedReminder.id ? updatedReminder : r)
          .toList();
      emit(state.copyWith(
        status: ReminderStatus.success,
        reminders: updated,
        successMessage: "Payment undone for '${event.reminder.title}'",
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to undo payment.'));
    }
  }

  void _onErrorCleared(
    ReminderErrorCleared event,
    Emitter<ReminderState> emit,
  ) =>
      emit(state.copyWith(clearError: true));

  void _onSuccessCleared(
    ReminderSuccessCleared event,
    Emitter<ReminderState> emit,
  ) =>
      emit(state.copyWith(clearSuccess: true));
}
