// ignore_for_file: depend_on_referenced_packages

import 'package:equatable/equatable.dart';

class AppError extends Equatable {
  AppError({
    required this.message,
  }) {
    timestamp = DateTime.now().microsecondsSinceEpoch;
  }

  final String message;
  late final int timestamp;

  @override
  List<Object?> get props => [message, timestamp];
}

class StateBase extends Equatable {
  final AppError? error;

  const StateBase({this.error});

  @override
  List<Object?> get props => [error];
}

class ControllerStateBase extends Equatable {
  const ControllerStateBase({this.error});

  final AppError? error;

  @override
  List<Object?> get props => [error];

  ControllerStateBase copyWith({AppError? error}) =>
      ControllerStateBase(error: error ?? this.error);
}
