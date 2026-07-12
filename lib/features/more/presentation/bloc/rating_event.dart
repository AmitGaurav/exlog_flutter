import 'package:equatable/equatable.dart';

abstract class RatingEvent extends Equatable {
  const RatingEvent();

  @override
  List<Object?> get props => [];
}

class RatingLoadRequested extends RatingEvent {
  const RatingLoadRequested();
}

class RatingSubmitRequested extends RatingEvent {
  final int rating;
  final String comment;
  const RatingSubmitRequested({required this.rating, required this.comment});

  @override
  List<Object?> get props => [rating, comment];
}
