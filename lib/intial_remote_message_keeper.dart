// /// Класс, который будет хранить initialMessage,
// /// который можно получить при открытии приложения из пуша
// abstract class InitialRemoteMessageKeeper {
//   static RemoteMessage? get message => _message;
//   static RemoteMessage? _message;

//   static void setMessage(RemoteMessage? newMessage) {
//     _message = newMessage;
//   }

//   static void removeMessage() {
//     setMessage(null);
//   }

//   static AbstractIntent? getInitialIntent({bool withRemove = true}) {
//     final intent = AbstractIntent.fromRemoteMessage(_message);

//     if (withRemove) {
//       removeMessage();
//     }

//     return intent;
//   }
// }
