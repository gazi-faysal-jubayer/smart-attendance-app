import 'app_exception.dart';

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.exception);
  final AppException exception;
}

extension ResultExtension<T> on Result<T> {
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  AppException? get exceptionOrNull => switch (this) {
        Success() => null,
        Failure(:final exception) => exception,
      };

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) =>
      switch (this) {
        Success(:final data) => success(data),
        Failure(:final exception) => failure(exception),
      };
}
