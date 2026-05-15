import 'dart:async';

/// Coalesces rapid calls (e.g. fare quote while typing or dragging map).
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 400)});

  final Duration duration;
  Timer? _timer;

  void run(Future<void> Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, () {
      unawaited(action());
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
