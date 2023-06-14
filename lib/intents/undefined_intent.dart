import 'package:firebase_notification_handler/intents/abstract_intent.dart';
import 'package:firebase_notification_handler/intents/arguments/empty_intent_arguments.dart';
import 'package:flutter/material.dart';

/// Неопределенный интент.
class UndefinedIntent extends AbstractIntent {
  @override
  EmptyIntentArguments get args => super.args as EmptyIntentArguments;

  UndefinedIntent()
      : super(
          args: const EmptyIntentArguments(),
        );

  @override
  Future<void> go({BuildContext? context}) async {}
}
