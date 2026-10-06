import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/data/models/app_notification.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../network/api_client.dart';

/// Wakes the app for a push received while it was backgrounded.
///
/// Must be a top-level entry point: Flutter spins up a fresh isolate for
/// it, so nothing from the running app is in scope. Showing the system
/// notification is FCM's job here; this only has to exist.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Registers the device for pushes and routes taps.
///
/// Delivery is best effort -- a push can be missed while the phone is off
/// or permission is denied -- so the inbox, not this class, is the source
/// of truth. Everything here is additive on top of it.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  /// The backend sends every push to this channel; the id must match
  /// exactly or Android 8+ drops the notification in some states.
  static const String channelId = 'order_updates';
  static const String channelName = 'Order updates';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Taps, from a push or a local notification, as a stream so the app can
  /// route them wherever navigation happens to live.
  final StreamController<AppNotification> _taps =
      StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get onTap => _taps.stream;

  NotificationsRepository? _repository;
  bool _isReady = false;

  /// A tap that arrived before anything was listening -- a cold start from
  /// a notification -- held until the app asks for it.
  AppNotification? _pending;

  AppNotification? takePending() {
    final AppNotification? held = _pending;
    _pending = null;
    return held;
  }

  /// Sets up Firebase, the channel and the listeners. Safe to call twice.
  Future<void> initialise({required ApiClient apiClient}) async {
    if (_isReady) return;
    _repository = NotificationsRepository(apiClient: apiClient);

    try {
      await Firebase.initializeApp();
      await _createChannel();
      _listen();
      _isReady = true;
    } catch (error) {
      // A phone without Play services, or a missing config, must not stop
      // the app starting -- the inbox still works without pushes.
      debugPrint('[push] initialise failed: $error');
    }
  }

  /// Asks for notification permission and registers the token.
  ///
  /// Called after login and on resume. If permission is refused the token
  /// is still registered, so pushes resume if it is granted later.
  Future<void> registerDevice({String? appVersion}) async {
    if (!_isReady) return;

    try {
      await FirebaseMessaging.instance.requestPermission();
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _repository?.registerDevice(
        fcmToken: token,
        appVersion: appVersion,
      );
    } catch (error) {
      debugPrint('[push] register failed: $error');
    }
  }

  Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.high,
    );

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _listen() {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Foreground: FCM shows nothing by itself, so the notification has to
    // be raised locally.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Tapped while the app was backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Tapped while the app was dead: the message is waiting at startup.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleTap(message);
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _repository?.registerDevice(fcmToken: token).catchError((_) {});
    });
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: _encodeTap(message),
    );
  }

  void _handleTap(RemoteMessage message) {
    _dispatch(
      AppNotification.fromPush(
        payload: Map<String, dynamic>.from(message.data),
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
      ),
    );
  }

  void _onLocalTap(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _dispatch(_decodeTap(payload));
  }

  void _dispatch(AppNotification notification) {
    // Mark it read as the user opens it, as the handoff doc asks. A failure
    // here must not block the navigation.
    if (notification.id > 0) {
      _repository?.markRead(notification.id).catchError((_) {});
    }

    if (_taps.hasListener) {
      _taps.add(notification);
    } else {
      _pending = notification;
    }
  }

  /// A local notification carries only a string, so the push data makes the
  /// round trip through one.
  static String _encodeTap(RemoteMessage message) {
    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      message.data,
    );
    payload['__title'] = message.notification?.title ?? '';
    payload['__body'] = message.notification?.body ?? '';
    return Uri(queryParameters: payload.map((k, v) => MapEntry(k, '$v')))
        .query;
  }

  static AppNotification _decodeTap(String payload) {
    final Map<String, String> parsed = Uri.splitQueryString(payload);
    return AppNotification.fromPush(
      payload: Map<String, dynamic>.from(parsed),
      title: parsed['__title'] ?? '',
      body: parsed['__body'] ?? '',
    );
  }
}
