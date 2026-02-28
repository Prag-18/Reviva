import 'dart:async';

class SessionEvents {
  SessionEvents._();

  static final StreamController<void> _unauthorizedController =
      StreamController<void>.broadcast();

  static Stream<void> get unauthorizedStream => _unauthorizedController.stream;

  static void emitUnauthorized() {
    if (!_unauthorizedController.isClosed) {
      _unauthorizedController.add(null);
    }
  }

  static Future<void> dispose() async {
    await _unauthorizedController.close();
  }
}
