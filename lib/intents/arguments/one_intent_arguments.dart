import 'package:firebase_notification_handler/intents/arguments/abstract_intent_arguments.dart';

/// Аргументы для интента с одним аргументом
class OneIntentArguments<T> extends AbstractIntentArguments {
  final T arg;
  const OneIntentArguments({required this.arg});

  factory OneIntentArguments.fromJson(
    Map<String, dynamic> json, {
    required String fieldName,
  }) {
    return OneIntentArguments<T>(
      arg: json[fieldName] as T,
    );
  }
  
}
