import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_notification_handler/intents/arguments/abstract_intent_arguments.dart';
import 'package:firebase_notification_handler/intents/undefined_intent.dart';
import 'package:flutter/material.dart';

/// Модель нового экрана из уведомления
abstract class AbstractIntent {
  final AbstractIntentArguments args;

  static AbstractIntent Function(String path, Map<String, dynamic> params)
      intentFactory = (_, __) {
    return UndefinedIntent();
  };

  AbstractIntent({
    required this.args,
  });

  factory AbstractIntent.fromJson(Map<String, dynamic> map) {
    final path = map['path'] as String?;

    if (path == null) {
      throw Exception(
        'Не передан путь для нового экрана в уведомлении',
      );
    }

    final params =
        (map['params'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return intentFactory(path, params);
  }

  static AbstractIntent? fromRemoteMessage(RemoteMessage? message) {
    final raw = message?.data['intent'] as String?;

    if (raw == null) return null;

    return AbstractIntent.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  /// Метод, пушит текущий интент
  Future<void> go({BuildContext? context});
}
