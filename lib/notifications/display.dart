import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/notifications.dart';
import '../host/android_notifications.dart';
import '../log.dart';
import '../model/binding.dart';
import '../model/localizations.dart';
import '../model/narrow.dart';
import '../model/notification.dart';
import '../widgets/app.dart';
import '../widgets/message_list.dart';
import '../widgets/page.dart';
import '../widgets/store.dart';
import '../widgets/theme.dart';

/// Service for configuring our Android "notification channel".
class NotificationChannelManager {
  @visibleForTesting
  static const kChannelId = 'messages-1';

  /// The vibration pattern we set for notifications.
  // We try to set a vibration pattern that, with the phone in one's pocket,
  // is both distinctly present and distinctly different from the default.
  // Discussion: https://chat.zulip.org/#narrow/stream/48-mobile/topic/notification.20vibration.20pattern/near/1284530
  @visibleForTesting
  static final kVibrationPattern = Int64List.fromList([0, 125, 100, 450]);

  /// Create our notification channel, if it doesn't already exist.
  //
  // NOTE when changing anything here: the changes will not take effect
  // for existing installs of the app!  That's because we'll have already
  // created the channel with the old settings, and they're in the user's
  // hands from there.  Our choices are:
  //
  //  * Leave the old settings in place for existing installs, so the
  //    changes only apply to new installs.
  //
  //  * Change `kChannelId`, so that we abandon the old channel and use
  //    a new one.  Existing installs will get the new settings.
  //
  //    This also means that if the user has changed any of the notification
  //    settings for the channel -- like "override Do Not Disturb", or "use
  //    a different sound", or "don't pop on screen" -- their changes get
  //    reset.  So this has to be done sparingly.
  //
  //    If we do this, we should also look for any channel with the old
  //    channel ID and delete it.  See zulip-mobile's `createNotificationChannel`
  //    in android/app/src/main/java/com/zulipmobile/notifications/NotificationChannelManager.kt .
  static Future<void> _ensureChannel() async {
    await ZulipBinding.instance.androidNotificationHost.createNotificationChannel(NotificationChannel(
      id: kChannelId,
      name: 'Messages', // TODO(i18n)
      importance: NotificationImportance.high,
      lightsEnabled: true,
      vibrationPattern: kVibrationPattern,
      // TODO(#340) sound
    ));
  }
}

/// Service for managing the notifications shown to the user.
class NotificationDisplayManager {
  static Future<void> init() async {
    await NotificationChannelManager._ensureChannel();
  }

  static void onFcmMessage(FcmMessage data, Map<String, dynamic> dataJson) {
    switch (data) {
      case MessageFcmMessage(): _onMessageFcmMessage(data, dataJson);
      case RemoveFcmMessage(): break; // TODO(#341) handle
      case UnexpectedFcmMessage(): break; // TODO(log)
    }
  }

  static Future<void> _onMessageFcmMessage(MessageFcmMessage data, Map<String, dynamic> dataJson) async {
    assert(debugLog('notif message content: ${data.content}'));
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    final groupKey = _groupKey(data);
    final conversationKey = _conversationKey(data, groupKey);

    final oldMessagingStyle = await ZulipBinding.instance.androidNotificationHost
      .getActiveNotificationMessagingStyleByTag(conversationKey);

    final MessagingStyle messagingStyle;
    if (oldMessagingStyle != null) {
      messagingStyle = oldMessagingStyle;
      messagingStyle.messages =
        oldMessagingStyle.messages.toList(); // Clone fixed-length list to growable.
    } else {
      messagingStyle = MessagingStyle(
        user: Person(
          key: _personKey(data.realmUri, data.userId),
          name: zulipLocalizations.notifSelfUser),
        messages: [],
        isGroupConversation: switch (data.recipient) {
          FcmMessageChannelRecipient() => true,
          FcmMessageDmRecipient(:var allRecipientIds) when allRecipientIds.length > 2 => true,
          FcmMessageDmRecipient() => false,
        });
    }

    // The title typically won't change between messages in a conversation, but we
    // update it anyway. This means a DM sender's display name gets updated if it's
    // changed, which is a rare edge case but probably good. The main effect is that
    // group-DM threads (pending #794) get titled with the latest sender, rather than
    // the first.
    messagingStyle.conversationTitle = switch (data.recipient) {
      FcmMessageChannelRecipient(:var streamName?, :var topic) =>
        '#$streamName > $topic',
      FcmMessageChannelRecipient(:var topic) =>
        '#(unknown channel) > $topic', // TODO get stream name from data
      FcmMessageDmRecipient(:var allRecipientIds) when allRecipientIds.length > 2 =>
        zulipLocalizations.notifGroupDmConversationLabel(
          data.senderFullName, allRecipientIds.length - 2), // TODO use others' names, from data
      FcmMessageDmRecipient() =>
        data.senderFullName,
    };

    messagingStyle.messages.add(MessagingStyleMessage(
      text: data.content,
      timestampMs: data.time * 1000,
      person: Person(
        key: _personKey(data.realmUri, data.senderId),
        name: data.senderFullName,
        iconBitmap: await _fetchBitmap(data.senderAvatarUrl))));

    await ZulipBinding.instance.androidNotificationHost.notify(
      // TODO the notification ID can be constant, instead of matching requestCode
      //   (This is a legacy of `flutter_local_notifications`.)
      id: notificationIdAsHashOf(conversationKey),
      tag: conversationKey,
      channelId: NotificationChannelManager.kChannelId,
      groupKey: groupKey,

      color: kZulipBrandColor.value,
      // TODO vary notification icon for debug
      smallIconResourceName: 'zulip_notification', // This name must appear in keep.xml too: https://github.com/zulip/zulip-flutter/issues/528

      messagingStyle: messagingStyle,
      number: messagingStyle.messages.length,

     contentIntent: PendingIntent(
        requestCode: 0,
        intent: AndroidIntent(
          action: IntentAction.view,
          uri: notificationOpenPayloadFromFcmMessage(data).toUri().toString()),

        // TODO is setting PendingIntentFlag.updateCurrent OK?
        //   (That's a legacy of `flutter_local_notifications`.)
        flags: PendingIntentFlag.immutable | PendingIntentFlag.updateCurrent,
        // TODO this doesn't set the Intent flags we set in zulip-mobile; is that OK?
        //   (This is a legacy of `flutter_local_notifications`.)
        ),
      autoCancel: true,
    );

    await ZulipBinding.instance.androidNotificationHost.notify(
      id: notificationIdAsHashOf(groupKey),
      tag: groupKey,
      channelId: NotificationChannelManager.kChannelId,
      groupKey: groupKey,
      isGroupSummary: true,

      color: kZulipBrandColor.value,
      // TODO vary notification icon for debug
      smallIconResourceName: 'zulip_notification', // This name must appear in keep.xml too: https://github.com/zulip/zulip-flutter/issues/528
      inboxStyle: InboxStyle(
        // TODO(#570) Show organization name, not URL
        summaryText: data.realmUri.toString()),

      // On Android 11 and lower, if autoCancel is not specified,
      // the summary notification may linger even after all child
      // notifications have been opened and cleared.
      // TODO(android-12): cut this autoCancel workaround
      autoCancel: true,
    );
  }

  /// A notification ID, derived as a hash of the given string key.
  ///
  /// The result fits in 31 bits, the size of a nonnegative Java `int`,
  /// so that it can be used as an Android notification ID.  (It's possible
  /// negative values would work too, which would add one bit.)
  ///
  /// This is a cryptographic hash, meaning that collisions are about as
  /// unlikely as one could hope for given the size of the hash.
  @visibleForTesting
  static int notificationIdAsHashOf(String key) {
    final bytes = sha256.convert(utf8.encode(key)).bytes;
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16)
      | ((bytes[3] & 0x7f) << 24);
  }

  static String _conversationKey(MessageFcmMessage data, String groupKey) {
    final conversation = switch (data.recipient) {
      FcmMessageChannelRecipient(:var streamId, :var topic) => 'stream:$streamId:$topic',
      FcmMessageDmRecipient(:var allRecipientIds) => 'dm:${allRecipientIds.join(',')}',
    };
    return '$groupKey|$conversation';
  }

  static String _groupKey(FcmMessageWithIdentity data) {
    // The realm URL can't contain a `|`, because `|` is not a URL code point:
    //   https://url.spec.whatwg.org/#url-code-points
    return "${data.realmUri}|${data.userId}";
  }

  static String _personKey(Uri realmUri, int userId) => "$realmUri|$userId";

  @visibleForTesting
  static NotificationOpenPayload notificationOpenPayloadFromFcmMessage(MessageFcmMessage data) {
    return NotificationOpenPayload(
      realm: data.realmUri,
      userId: data.userId,
      narrow: switch (data.recipient) {
        FcmMessageChannelRecipient(:final streamId, :final topic) =>
          TopicNarrow(streamId, topic),
        FcmMessageDmRecipient(:final allRecipientIds) =>
          DmNarrow(allRecipientIds: allRecipientIds, selfUserId: data.userId),
      });
  }

  static Future<void> navigateForNotification(Uri url) async {
    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final result = getRouteForNotification(context, url);
    if (result == null) return; // TODO(log)
    await navigator.push(result.$1);
  }

  static (Route<dynamic>, int)? getRouteForNotification(BuildContext context, Uri url) {
    final NotificationOpenPayload payload;
    try {
      payload = NotificationOpenPayload.parse(url);
    } catch (e, st) {
      assert(debugLog('$e\n$st'));
      return null; // TODO(log)
    }
    final globalStore = GlobalStoreWidget.of(context);
    final account = globalStore.accounts.firstWhereOrNull((account) =>
      account.realmUrl == payload.realm && account.userId == payload.userId);
    if (account == null) return null; // TODO(log)

    assert(debugLog('  account: $account, narrow: ${payload.narrow}'));
    // TODO(nav): Better interact with existing nav stack on notif open
    final route = MaterialAccountWidgetRoute<void>(accountId: account.id,
      // TODO(#82): Open at specific message, not just conversation
      page: MessageListPage(initNarrow: payload.narrow));
    return (route, account.id);
  }

  static Future<Uint8List?> _fetchBitmap(Uri url) async {
    try {
      // TODO timeout to prevent waiting indefinitely
      final resp = await http.get(url);
      if (resp.statusCode == HttpStatus.ok) {
        return resp.bodyBytes;
      }
    } catch (e) {
      // TODO(log)
    }
    return null;
  }
}
