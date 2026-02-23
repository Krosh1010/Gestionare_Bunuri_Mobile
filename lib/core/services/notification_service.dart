import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cheia pentru stocarea ID-urilor notificărilor deja afișate
const String kShownNotificationsKey = 'shown_notification_ids';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Timer? _periodicTimer;

  // ─── Inițializare ──────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // ─── Cerere permisiuni ─────────────────────────────────────────
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
      return false;
    } else if (Platform.isIOS) {
      final iosPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return false;
    }
    return true;
  }

  // ─── Pornire verificare periodică (Timer în app) ───────────────
  static void startPeriodicCheck({
    Duration interval = const Duration(minutes: 15),
  }) {
    stopPeriodicCheck();

    // Verifică imediat la pornire
    checkAndShowNotifications();

    // Apoi verifică periodic
    _periodicTimer = Timer.periodic(interval, (_) {
      checkAndShowNotifications();
    });

    debugPrint('🔔 [NotificationService] Verificare periodică pornită (la fiecare ${interval.inMinutes} min)');
  }

  // ─── Oprire verificare periodică ───────────────────────────────
  static void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  // ─── Verifică API-ul și afișează notificări noi ────────────────
  static Future<void> checkAndShowNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) return;

      // Citește ID-urile notificărilor deja afișate
      final shownIds =
          prefs.getStringList(kShownNotificationsKey) ?? <String>[];

      // Apel API direct
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://192.168.1.3:5288/api',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await dio.get('/Notifications');
      final notifications =
          (response.data as List).cast<Map<String, dynamic>>();

      int notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final newShownIds = List<String>.from(shownIds);

      for (final notif in notifications) {
        final id = notif['id']?.toString() ?? '';
        if (id.isEmpty || shownIds.contains(id)) continue;

        final message = notif['message']?.toString() ?? '';
        final type = notif['type'] as int? ?? 0;

        final title = type == 0
            ? '⚠️ Garanție'
            : type == 1
                ? '🛡️ Asigurare'
                : '🔔 Notificare';

        await _showNotification(
          id: notifId++,
          title: title,
          body: message,
          payload: jsonEncode(notif),
        );

        newShownIds.add(id);
      }

      // Păstrează doar ultimele 200 de ID-uri
      if (newShownIds.length > 200) {
        newShownIds.removeRange(0, newShownIds.length - 200);
      }
      await prefs.setStringList(kShownNotificationsKey, newShownIds);
    } catch (e) {
      debugPrint('❌ [NotificationService] Eroare la verificare: $e');
    }
  }

  // ─── Afișare notificare locală ─────────────────────────────────
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'gestionare_bunuri_channel',
      'Notificări Bunuri',
      channelDescription: 'Notificări despre garanții și asigurări',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(id, title, body, notificationDetails, payload: payload);
  }

  // ─── Afișare notificare manuală (din app) ──────────────────────
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
    );
  }

  // ─── Callback la tap pe notificare ─────────────────────────────
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notificare apăsată: ${response.payload}');
  }

  // ─── Curăță lista de notificări afișate (la logout) ────────────
  static Future<void> clearShownNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kShownNotificationsKey);
  }
}
