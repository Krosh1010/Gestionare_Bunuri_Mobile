import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handler pentru mesaje primite în background / app închisă.
/// Trebuie să fie o funcție top-level (nu metodă de clasă).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [FCM] Mesaj primit în background: ${message.messageId}');
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _fcmTokenKey = 'fcm_device_token';
  static const String _baseUrl = 'http://192.168.1.6:5288/api';

  /// Notification channel pentru Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'asset_guard_notifications',
    'Asset Guard Notifications',
    description: 'Notificări push pentru garanții și asigurări',
    importance: Importance.high,
  );

  // ─── Inițializare completă FCM ──────────────────────────────────
  static Future<void> initialize() async {
    // Creează notification channel-ul pe Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Inițializează local notifications pentru foreground
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Setează handler-ul pentru background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Ascultă mesajele în foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Ascultă tap pe notificare (app deschisă din background)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Verifică dacă app-ul a fost deschis dintr-o notificare (app închisă)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage.data);
    }

    // Ascultă refresh-ul tokenului FCM
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    debugPrint('🔔 [FCM] Serviciul FCM a fost inițializat');
  }

  // ─── Cerere permisiuni notificări ───────────────────────────────
  static Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final granted = settings.authorizationStatus ==
        AuthorizationStatus.authorized;
    debugPrint('🔔 [FCM] Permisiune notificări: ${granted ? "acordată" : "refuzată"}');
    return granted;
  }

  // ─── Obține FCM Token ───────────────────────────────────────────
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_fcmTokenKey, token);
      }
      debugPrint('🔔 [FCM] Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ [FCM] Eroare la obținerea tokenului: $e');
      return null;
    }
  }

  // ─── Înregistrare token la backend (după login) ─────────────────
  static Future<void> registerDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');
      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('⚠️ [FCM] Nu există JWT token, nu se poate înregistra');
        return;
      }

      final fcmToken = await getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ [FCM] Nu s-a putut obține FCM token');
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      ));

      await dio.post(
        '/devicetoken/register',
        data: {
          'token': fcmToken,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );

      debugPrint('✅ [FCM] Token înregistrat la backend');
    } catch (e) {
      debugPrint('❌ [FCM] Eroare la înregistrarea tokenului: $e');
    }
  }

  // ─── Ștergere token de la backend (la logout) ───────────────────
  static Future<void> unregisterDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');
      final fcmToken = prefs.getString(_fcmTokenKey);

      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('⚠️ [FCM] Nu există JWT token, nu se poate dezînregistra');
        return;
      }
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ [FCM] Nu există FCM token salvat');
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      ));

      await dio.post(
        '/devicetoken/unregister',
        data: {
          'token': fcmToken,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );

      // Șterge tokenul FCM din SharedPreferences
      await prefs.remove(_fcmTokenKey);

      debugPrint('✅ [FCM] Token dezînregistrat de la backend');
    } catch (e) {
      debugPrint('❌ [FCM] Eroare la dezînregistrarea tokenului: $e');
    }
  }

  // ─── Handler: mesaj primit cu app în foreground ─────────────────
  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FCM] Mesaj în foreground: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    // Afișează notificarea local (pe Android, notificările FCM nu apar
    // automat când app-ul e în foreground)
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title ?? '🔔 Notificare',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // ─── Handler: utilizatorul a apăsat pe notificare (din background) ──
  static void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 [FCM] Notificare apăsată (din background): ${message.data}');
    _handleNotificationNavigation(message.data);
  }

  // ─── Handler: tap pe notificare locală (din foreground) ──────────
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 [FCM] Notificare locală apăsată: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationNavigation(data);
      } catch (_) {}
    }
  }

  // ─── Navigare la conținutul notificării ──────────────────────────
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Poți adăuga logică de navigare aici în funcție de datele din notificare
    // Exemplu: dacă data conține un 'assetId', navighează la detalii
    debugPrint('🔔 [FCM] Navigare cu date: $data');
  }

  // ─── Handler: token FCM a fost reînnoit ─────────────────────────
  static void _onTokenRefresh(String newToken) async {
    debugPrint('🔔 [FCM] Token reînnoit: $newToken');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, newToken);

    // Re-înregistrează la backend doar dacă utilizatorul e autentificat
    final jwtToken = prefs.getString('jwt_token');
    if (jwtToken != null && jwtToken.isNotEmpty) {
      await registerDeviceToken();
    }
  }
}
