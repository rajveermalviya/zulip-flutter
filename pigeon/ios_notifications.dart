import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/ios_notifications.g.dart',
  swiftOut: 'ios/Runner/Notifications.g.swift',
))

class NotificationDataJson{
  const NotificationDataJson(this.json);
  final Map<Object?, Object?> json;
}

@HostApi()
abstract class IosNotificationHostApi {
  NotificationDataJson? getNotificationDataFromLaunch();
}

@EventChannelApi()
abstract class NotificationOpenEvents {
  NotificationDataJson notificationTapEvents();
}
