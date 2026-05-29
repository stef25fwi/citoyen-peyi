import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'firebase_auth_service.dart';
import 'new_poll_badge_service.dart';

class PushNotificationService {
  PushNotificationService({http.Client? client})
      : _client = client ?? http.Client();

  static final PushNotificationService instance = PushNotificationService();

  final http.Client _client;
  bool _foregroundListenerStarted = false;

  Future<void> initialize() async {
    if (_foregroundListenerStarted || !AppConfig.isFirebaseConfigured) return;
    _foregroundListenerStarted = true;
    FirebaseMessaging.onMessage.listen((_) {
      NewPollBadgeService.instance.check();
    });
  }

  Future<void> registerForCitizenCommune({
    required String rawCode,
    required String communeId,
    required String communeName,
  }) async {
    if (!AppConfig.isFirebaseConfigured) return;
    if (communeId.trim().isEmpty && communeName.trim().isEmpty) return;
    if (kIsWeb && AppConfig.pushVapidKey.trim().isEmpty) return;

    try {
      await FirebaseAuthService.instance.initialize();
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb ? AppConfig.pushVapidKey.trim() : null,
      );
      if (token == null || token.trim().isEmpty) return;

      final base = AppConfig.apiBaseUrl.trim();
      if (base.isEmpty) return;
      await _client
          .post(
            Uri.parse('$base/api/notifications/subscribe'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': rawCode.trim(),
              'token': token.trim(),
              'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
              'communeId': communeId.trim(),
              'communeName': communeName.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[PushNotificationService] registration skipped: $error');
      }
    }
  }
}
