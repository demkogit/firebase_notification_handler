library firebase_notification_handler;

import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_notification_handler/intial_remote_message_keeper.dart';
import 'package:firebase_notification_handler/local_notification_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Хендлер для инициализации FirebaseMessaging.
abstract class FirebaseNotificationHandler {
  static final messaging = FirebaseMessaging.instance;

  /// Ининциализация методов для работы с FirebaseMessaging.
  static Future<void> init({
    void Function(String)? onToken,
    void Function(RemoteMessage)? onNotificationTap,
    required AndroidNotificationDetails androidLocalNotificationDetails,
    AndroidNotificationChannel? androidLocalNotificationChannel,
  }) async {
    unawaited(messaging.requestPermission());
    unawaited(messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    ));

    if (Platform.isAndroid) {
      LocalNotificationHandler.init(
        onLocalNotificationTap: onNotificationTap ?? (_) {},
        androidNotificationDetails: androidLocalNotificationDetails,
        androidNotificationChannel: androidLocalNotificationChannel,
      );
    }

    // Слушаем токен, если он вдруг обновится
    messaging.onTokenRefresh.listen(onToken);

    // Запоминаем начальное сообщение
    InitialRemoteMessageKeeper.setMessage(await messaging.getInitialMessage());

    // Слушаем сообщения
    FirebaseMessaging.onMessage.listen(
      (message) {
        if (Platform.isAndroid) {
          LocalNotificationHandler.showNotification(message);
        }
      },
    );

    // Слушаем нажатия по уведомлению,
    // которое показывается самим Firebase Sdk
    FirebaseMessaging.onMessageOpenedApp.listen(onNotificationTap);

    // Запрашиваем токен и выводим его в консоль
    _getToken();
  }

  static Future<void> _getToken() async {
    try {
      final token = await messaging.getToken();
      debugPrint('*** firebase token ***\n$token\n');
    } catch (e) {
      debugPrint('Ошибка: Не удалось получить firebase токен');
    }
  }

  static Future<void> updateToken(void Function(String)? onToken) async {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        onToken?.call(token);
      }
    } catch (e) {
      debugPrint('Ошибка: Не удалось получить firebase токен');
    }
  }
}



/// Метод, который запускается, когда происходит нажатие по уведомлению от Firebase Sdk.
///
/// На ios этот метод будет запускаться всегда,
/// т.к. для ios Firebase Sdk показывает уведомления в любом состоянии приложения.
///
/// На android будет запускаться, когда приложение свернуто.
/// (LocalNotificationHandler показывает уведомление, когда приложение открыто).
// Future<void> messageOpenHandler(
//   StackRouter router,
//   RemoteMessage message,
// ) async {
//   tryNavigate(router, message);
//   debugPrint('messageOpenHandler ${message.messageId}');
// }

// /// Пока что такой переход при нажатии по пушу.
// void tryNavigate(
//   StackRouter router,
//   RemoteMessage message,
// ) {
//   try {
//     debugPrint('message: ${message.toMap()}');
//     final intent = AbstractIntentModel.fromRemoteMessage(message);
//     intent?.router = router;

//     intent?.go();
//   } catch (e) {
//     log(
//       'Ошибка при нажатии по пушу',
//       error: e,
//       stackTrace: StackTrace.current,
//     );
//   }
// }

// /// Прослушка уведомлений в бэкрграунде.
// ///
// /// К сожалению нельзя контролировать показ уведомления.
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(
//   RemoteMessage message,
// ) async {
//   await Firebase.initializeApp();
//   debugPrint('Handling a background message ${message.messageId}');
// }
