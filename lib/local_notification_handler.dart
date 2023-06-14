import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

abstract class LocalNotificationHandler {
  /// Канал уведомлений для android (для ios нет, т.к. эти уведомления показываются только на андроид).
  static late AndroidNotificationChannel channel;

  /// Плагин для работы с локальными уведомлениями.
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  static AndroidNotificationDetails? _androidNotificationDetails;

  /// Инициализация плагина для показа локальных уведомлений.
  static Future<void> init({
    required void Function(RemoteMessage) onLocalNotificationTap,
    required AndroidNotificationDetails androidNotificationDetails,
    AndroidNotificationChannel? androidNotificationChannel,
  }) async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    channel = androidNotificationChannel ??
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        );

    _androidNotificationDetails = androidNotificationDetails;

    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
      ),
      // Здесь происходит логика нажатия на локальное уведомление
      // Чтобы здесь получить инфу о уведомлении надо в
      // flutterLocalNotificationsPlugin.show закинуть payload
      onDidReceiveNotificationResponse: (details) {
        if ((details.payload?.isNotEmpty ?? false)) {
          final rawMessage = jsonDecode(
            details.payload!,
          ) as Map<String, dynamic>;
          final message = RemoteMessage.fromMap(rawMessage);
          onLocalNotificationTap(message);
        }
      },
    );

    // Запрос разрешения на показ уведомлений
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    // Созжание канала уведомлений
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Метод показа локальных уведомлений.
  static Future<void> showNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    final android = message.notification?.android;

    final image = _getImageUrl(message);
    final picturePath = await _downloadAndSavePicture(
      image,
      message.messageId!,
    );

    if (notification != null && android != null) {
      // ignore: unawaited_futures
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        _getNotificationDetails(
          notification.title ?? '',
          notification.body ?? '',
          picturePath,
          true,
        ),

        // Сюда закидывается строка, которая отлавливается после нажатия на локальное уведомление
        // (onDidReceiveNotificationResponse)
        payload: jsonEncode(message.toMap()),
      );
    }
  }

  static NotificationDetails _getNotificationDetails(
    String title,
    String body,
    String? picturePath,
    bool showBigPicture,
  ) {
    return NotificationDetails(
      android: _androidNotificationDetails!.copyWith(
        styleInformation: _buildBigPictureStyleInformation(
          title,
          body,
          picturePath,
          showBigPicture,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}

Future<String?> _downloadAndSavePicture(
  String? url,
  String fileName,
) async {
  if (url == null) return null;
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';

  try {
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    // ignore: avoid-throw-in-catch-block
    throw Exception('Не удалось скачать картинку для уведомления');
  }

  return filePath;
}

String? _getImageUrl(RemoteMessage message) {
  if (Platform.isIOS && message.notification?.apple != null) {
    return message.notification!.apple?.imageUrl;
  }
  if (Platform.isAndroid && message.notification?.android != null) {
    return message.notification!.android?.imageUrl;
  }

  return null;
}

BigPictureStyleInformation? _buildBigPictureStyleInformation(
  String title,
  String body,
  String? picturePath,
  bool showBigPicture,
) {
  if (picturePath == null) return null;
  final filePath = FilePathAndroidBitmap(picturePath);
  return BigPictureStyleInformation(
    showBigPicture ? filePath : const FilePathAndroidBitmap('empty'),
    largeIcon: filePath,
    contentTitle: title,
    htmlFormatContentTitle: true,
    summaryText: body,
    htmlFormatSummaryText: true,
    hideExpandedLargeIcon: true,
  );
}

extension AndroidNotificationDetailsExt on AndroidNotificationDetails {
  AndroidNotificationDetails copyWith({
    String? channelDescription,
    String? icon,
    Importance? importance,
    Priority? priority,
    StyleInformation? styleInformation,
    bool? playSound,
    AndroidNotificationSound? sound,
    bool? enableVibration,
    Int64List? vibrationPattern,
    String? groupKey,
    bool? setAsGroupSummary,
    GroupAlertBehavior? groupAlertBehavior,
    bool? autoCancel,
    bool? ongoing,
    Color? color,
    AndroidBitmap<Object>? largeIcon,
    bool? onlyAlertOnce,
    bool? showWhen,
    bool? usesChronometer,
    bool? chronometerCountDown,
    bool? channelShowBadge,
    bool? showProgress,
    int? maxProgress,
    int? progress,
    bool? indeterminate,
    AndroidNotificationChannelAction? channelAction,
    bool? enableLights,
    Color? ledColor,
    int? ledOnMs,
    int? ledOffMs,
    String? ticker,
    NotificationVisibility? visibility,
    int? timeoutAfter,
    AndroidNotificationCategory? category,
    bool? fullScreenIntent,
    String? shortcutId,
    Int32List? additionalFlags,
    String? subText,
    String? tag,
    List<AndroidNotificationAction>? actions,
    bool? colorized,
    int? number,
    AudioAttributesUsage? audioAttributesUsage,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription ?? this.channelDescription,
      icon: icon ?? this.icon,
      importance: importance ?? this.importance,
      priority: priority ?? this.priority,
      styleInformation: styleInformation ?? this.styleInformation,
      playSound: playSound ?? this.playSound,
      sound: sound ?? this.sound,
      enableVibration: enableVibration ?? this.enableVibration,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      groupKey: groupKey ?? this.groupKey,
      setAsGroupSummary: setAsGroupSummary ?? this.setAsGroupSummary,
      groupAlertBehavior: groupAlertBehavior ?? this.groupAlertBehavior,
      autoCancel: autoCancel ?? this.autoCancel,
      ongoing: ongoing ?? this.ongoing,
      color: color ?? this.color,
      largeIcon: largeIcon ?? this.largeIcon,
      onlyAlertOnce: onlyAlertOnce ?? this.onlyAlertOnce,
      showWhen: showWhen ?? this.showWhen,
      usesChronometer: usesChronometer ?? this.usesChronometer,
      chronometerCountDown: chronometerCountDown ?? this.chronometerCountDown,
      channelShowBadge: channelShowBadge ?? this.channelShowBadge,
      showProgress: showProgress ?? this.showProgress,
      maxProgress: maxProgress ?? this.maxProgress,
      progress: progress ?? this.progress,
      indeterminate: indeterminate ?? this.indeterminate,
      channelAction: channelAction ?? this.channelAction,
      enableLights: enableLights ?? this.enableLights,
      ledColor: ledColor ?? this.ledColor,
      ledOnMs: ledOnMs ?? this.ledOnMs,
      ledOffMs: ledOffMs ?? this.ledOffMs,
      ticker: ticker ?? this.ticker,
      visibility: visibility ?? this.visibility,
      timeoutAfter: timeoutAfter ?? this.timeoutAfter,
      category: category ?? this.category,
      fullScreenIntent: fullScreenIntent ?? this.fullScreenIntent,
      shortcutId: shortcutId ?? this.shortcutId,
      additionalFlags: additionalFlags ?? this.additionalFlags,
      subText: subText ?? this.subText,
      tag: tag ?? this.tag,
      actions: actions ?? this.actions,
      colorized: colorized ?? this.colorized,
      number: number ?? this.number,
      audioAttributesUsage: audioAttributesUsage ?? this.audioAttributesUsage,
    );
  }
}
