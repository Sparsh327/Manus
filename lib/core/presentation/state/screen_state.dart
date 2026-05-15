enum ScreenStatus { initial, loading, loaded, error }

class ScreenState<T> {
  final ScreenStatus status;
  final T? data;
  final String? error;
  final bool isLoadingMore;

  const ScreenState({
    this.status = ScreenStatus.initial,
    this.data,
    this.error,
    this.isLoadingMore = false,
  });

  factory ScreenState.initial() => const ScreenState(status: ScreenStatus.initial);
  factory ScreenState.loading() => const ScreenState(status: ScreenStatus.loading);
  factory ScreenState.loaded(T data) => ScreenState(status: ScreenStatus.loaded, data: data);
  factory ScreenState.error(String message) =>
      ScreenState(status: ScreenStatus.error, error: message);

  ScreenState<T> copyWith({
    ScreenStatus? status,
    T? data,
    String? error,
    bool? isLoadingMore,
  }) {
    return ScreenState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
