import 'api_exception.dart';

/// The four states every network-backed section of the UI can be in.
sealed class AsyncValue<T> {
  const AsyncValue();
}

/// Nothing requested yet.
class AsyncIdle<T> extends AsyncValue<T> {
  const AsyncIdle();
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading([this.label]);

  /// Shown under the spinner. Worth setting for the slow LLM endpoints — a
  /// labelled 60s wait reads much shorter than an unlabelled 20s one.
  final String? label;
}

class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);

  final T value;
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.error);

  final ApiException error;
}

extension AsyncValueX<T> on AsyncValue<T> {
  T? get dataOrNull =>
      this is AsyncData<T> ? (this as AsyncData<T>).value : null;

  bool get isLoading => this is AsyncLoading<T>;

  bool get hasData => this is AsyncData<T>;
}
