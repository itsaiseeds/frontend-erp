import 'dart:async';

import 'metadata_service.dart';
import 'storage_service.dart';

class SessionGuard {
  SessionGuard._();

  static final StreamController<void> _expiryController =
      StreamController<void>.broadcast();

  static Stream<void> get onSessionExpired => _expiryController.stream;

  static Future<void> endSession() async {
    await StorageService.clearSession();
    MetadataService.instance.reset();
    if (!_expiryController.isClosed) _expiryController.add(null);
  }
}
