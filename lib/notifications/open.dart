
import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../host/ios_notifications.g.dart';
import '../log.dart';
import '../model/binding.dart';
import '../model/narrow.dart';
import '../widgets/app.dart';
import '../widgets/dialog.dart';
import '../widgets/message_list.dart';
import '../widgets/page.dart';
import '../widgets/store.dart';

class NotificationOpenManager {
  static NotificationOpenManager get instance => (_instance ??= NotificationOpenManager._());
  static NotificationOpenManager? _instance;

  NotificationOpenManager._();

  NotificationDataJson? _notifLaunchData;

  Future<void> init() async {
    _notifLaunchData = await ZulipBinding.instance.iosNotificationHost.getNotificationDataFromLaunch();

    ZulipBinding.instance
      .notificationTapEventsStream()
      .listen(_navigateForNotification);
  }

  AccountRoute<void>? routeForNotificationFromLaunch({required BuildContext context}) {
    final data = _notifLaunchData;
    if (data == null) return null;
    assert(debugLog('opened notif: ${jsonEncode(data.json)}'));
    return _routeForNotification(context, data);
  }

  AccountRoute<void>? _routeForNotification(BuildContext context, NotificationDataJson data) {
    final globalStore = GlobalStoreWidget.of(context);
    final payload = NotificationOpenData.fromIos(data);

    final account = globalStore.accounts.firstWhereOrNull(
      (account) => account.realmUrl.origin == payload.realmUrl.origin
                && account.userId == payload.userId);
    if (account == null) { // TODO(log)
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorNotificationOpenTitle,
        message: zulipLocalizations.errorNotificationOpenAccountMissing);
      return null;
    }

    return MessageListPage.buildRoute(
      accountId: account.id,
      // TODO(#82): Open at specific message, not just conversation
      narrow: payload.narrow);
  }

  Future<void> _navigateForNotification(NotificationDataJson data) async {
    assert(debugLog('opened notif: ${jsonEncode(data.json)}'));

    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final route = _routeForNotification(context, data);
    if (route == null) return; // TODO(log)

    // TODO(nav): Better interact with existing nav stack on notif open
    unawaited(navigator.push(route));
  }
}

class NotificationOpenData {
  final Uri realmUrl;
  final int userId;
  final Narrow narrow;

  NotificationOpenData({
    required this.realmUrl,
    required this.userId,
    required this.narrow,
  });

  factory NotificationOpenData.fromIos(NotificationDataJson notifData) {
    if (notifData.json case {'aps': {'custom': {
      'zulip': {
        'user_id': final int userId,
        'sender_id': final int senderId,
        'recipient_type': final String recipientType,
      } && final zulipData,
    }}}) {
      final String realmUrl;
      switch (zulipData) {
        case {'realm_url': final String value}:
          realmUrl = value;
        case {'realm_uri': final String value}:
          realmUrl = value;
        default:
          throw const FormatException();
      }

      final Narrow narrow;
      switch (recipientType) {
        case 'stream':
          if (zulipData case {
            'stream_id': final int streamId,
            'topic': final String topic,
          }) {
            narrow = TopicNarrow(streamId, TopicName(topic));
          } else {
            throw const FormatException();
          }

        case 'private':
          final allRecipientIds = <int>{};
          if (zulipData case {'pm_users': final String pmUsers}) {
            allRecipientIds.addAll(
              pmUsers.split(',').map((e) => int.parse(e, radix: 10)));
          } else {
            allRecipientIds.addAll([senderId, userId]);
          }

          narrow = DmNarrow(
            allRecipientIds: allRecipientIds.toList(growable: false)..sort(),
            selfUserId: userId);
        default:
          throw const FormatException();
      }

      return NotificationOpenData(
        realmUrl: Uri.parse(realmUrl),
        userId: userId,
        narrow: narrow);
    } else {
      // TODO(dart): simplify after https://github.com/dart-lang/language/issues/2537
      throw const FormatException();
    }
  }
}
