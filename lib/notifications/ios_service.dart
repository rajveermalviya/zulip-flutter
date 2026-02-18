import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../host/ios_notifications.g.dart';

@pragma('vm:entry-point')
Future<void> iosNotificationServiceMain() async {
  print('dart: iosNotificationServiceMain');
  WidgetsFlutterBinding.ensureInitialized();

  final iosNotifFlutterApiImpl = _IosNotifFlutterApiImpl();
  IosNotifFlutterApi.setUp(iosNotifFlutterApiImpl);
}

class _IosNotifFlutterApiImpl extends IosNotifFlutterApi {
  @override
  Future<MutatedNotificationContent> didReceivePushNotification(NotificationContent content) async {
    print("dart: _IosNotifFlutterApiImpl.didReceivePushNotification");
    print("dart: content.payload=${jsonEncode(content.payload)}");

    final parsed = ApnsPayload.parseApnsPayload(content.payload);

    return MutatedNotificationContent(
      title: "${parsed.title} (from dart)",
      body: parsed.body);
  }
}

class ApnsPayload {
  const ApnsPayload._({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  factory ApnsPayload.parseApnsPayload(Map<Object?, Object?> payload) {
    if (payload case {
      "aps": {
        "alert": {
          "title": final String title,
          "body": final String body,
        },
      },
    }) {
      return ApnsPayload._(title: title, body: body);
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }
}
