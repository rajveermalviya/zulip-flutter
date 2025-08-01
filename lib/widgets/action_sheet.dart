import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../api/route/messages.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/binding.dart';
import '../model/content.dart';
import '../model/emoji.dart';
import '../model/internal_link.dart';
import '../model/narrow.dart';
import 'actions.dart';
import 'button.dart';
import 'color.dart';
import 'compose_box.dart';
import 'content.dart';
import 'dialog.dart';
import 'emoji.dart';
import 'emoji_reaction.dart';
import 'icons.dart';
import 'inset_shadow.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'topic_list.dart';

void _showActionSheet(
  BuildContext pageContext, {
  Widget? header,
  required List<Widget> optionButtons,
}) {
  // Could omit this if we need _showActionSheet outside a per-account context.
  final accountId = PerAccountStoreWidget.accountIdOf(pageContext);

  showModalBottomSheet<void>(
    context: pageContext,
    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (BuildContext _) {
      final designVariables = DesignVariables.of(pageContext);
      return PerAccountStoreWidget(
        accountId: accountId,
        child: Semantics(
          role: SemanticsRole.menu,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (header != null)
                  Flexible(
                    // TODO(upstream) Enforce a flex ratio (e.g. 1:3)
                    //   only when the header height plus the buttons' height
                    //   exceeds available space. Otherwise let one or the other
                    //   grow to fill available space even if it breaks the ratio.
                    //   Needs support for separate properties like `flex-grow`
                    //   and `flex-shrink`.
                    flex: 1,
                    child: InsetShadowBox(
                      top: 8, bottom: 8,
                      color: designVariables.bgContextMenu,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: header)))
                else
                  SizedBox(height: 8),
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: InsetShadowBox(
                          top: 8, bottom: 8,
                          color: designVariables.bgContextMenu,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: MenuButtonsShape(buttons: optionButtons)))),
                        const ActionSheetCancelButton(),
                      ]))),
              ]))));
    });
}

/// A button in an action sheet.
///
/// When built from server data, the action sheet ignores changes in that data;
/// we intentionally don't live-update the buttons on events.
/// If a button's label, action, or position changes suddenly,
/// it can be confusing and make the on-tap behavior unexpected.
/// Better to let the user decide to tap
/// based on information that's comfortably in their working memory,
/// even if we sometimes have to explain (where we handle the tap)
/// that that information has changed and they need to decide again.
///
/// (Even if we did live-update the buttons, it's possible anyway that a user's
/// action can race with a change that's already been applied on the server,
/// because it takes some time for the server to report changes to us.)
abstract class ActionSheetMenuItemButton extends StatelessWidget {
  const ActionSheetMenuItemButton({super.key, required this.pageContext});

  IconData get icon;
  String label(ZulipLocalizations zulipLocalizations);

  /// Called when the button is pressed, after dismissing the action sheet.
  ///
  /// If the action may take a long time, this method is responsible for
  /// arranging any form of progress feedback that may be desired.
  ///
  /// For operations that need a [BuildContext], see [pageContext].
  void onPressed();

  /// A context within the [MessageListPage] this action sheet was
  /// triggered from.
  final BuildContext pageContext;

  /// The [MessageListPageState] this action sheet was triggered from.
  ///
  /// Uses the inefficient [BuildContext.findAncestorStateOfType];
  /// don't call this in a build method.
  MessageListPageState findMessageListPage() {
    assert(pageContext.mounted,
      'findMessageListPage should be called only when pageContext is known to still be mounted');
    return MessageListPage.ancestorOf(pageContext);
  }

  void _handlePressed(BuildContext context) {
    // Dismiss the enclosing action sheet immediately,
    // for swift UI feedback that the user's selection was received.
    Navigator.of(context).pop();

    assert(pageContext.mounted);
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return ZulipMenuItemButton(
      icon: icon,
      label: label(zulipLocalizations),
      onPressed: () => _handlePressed(context),
    );
  }
}

class ActionSheetCancelButton extends StatelessWidget {
  const ActionSheetCancelButton({super.key});

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.all(10),
        foregroundColor: designVariables.contextMenuCancelText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        splashFactory: NoSplash.splashFactory,
      ).copyWith(backgroundColor: WidgetStateColor.fromMap({
        WidgetState.pressed: designVariables.contextMenuCancelPressedBg,
        ~WidgetState.pressed: designVariables.contextMenuCancelBg,
      })),
      onPressed: () {
        Navigator.pop(context);
      },
      child: Text(ZulipLocalizations.of(context).dialogCancel,
        style: const TextStyle(fontSize: 20, height: 24 / 20)
          .merge(weightVariableTextStyle(context, wght: 600))));
  }
}

/// Show a sheet of actions you can take on a channel.
///
/// Needs a [PageRoot] ancestor.
void showChannelActionSheet(BuildContext context, {
  required int channelId,
}) {
  final pageContext = PageRoot.contextOf(context);
  final store = PerAccountStoreWidget.of(pageContext);

  final optionButtons = <ActionSheetMenuItemButton>[
    TopicListButton(pageContext: pageContext, channelId: channelId),
  ];

  final unreadCount = store.unreads.countInChannelNarrow(channelId);
  if (unreadCount > 0) {
    optionButtons.add(
      MarkChannelAsReadButton(pageContext: pageContext, channelId: channelId));
  }

  optionButtons.add(
    CopyChannelLinkButton(channelId: channelId, pageContext: pageContext));

  _showActionSheet(pageContext, optionButtons: optionButtons);
}

class TopicListButton extends ActionSheetMenuItemButton {
  const TopicListButton({
    super.key,
    required this.channelId,
    required super.pageContext,
  });

  final int channelId;

  @override
  IconData get icon => ZulipIcons.topics;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionListOfTopics;
  }

  @override
  void onPressed() {
    Navigator.push(pageContext,
      TopicListPage.buildRoute(context: pageContext, streamId: channelId));
  }
}

class MarkChannelAsReadButton extends ActionSheetMenuItemButton {
  const MarkChannelAsReadButton({
    super.key,
    required this.channelId,
    required super.pageContext,
  });

  final int channelId;

  @override
  IconData get icon => ZulipIcons.message_checked;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionMarkChannelAsRead;
  }

  @override
  void onPressed() async {
    final narrow = ChannelNarrow(channelId);
    await ZulipAction.markNarrowAsRead(pageContext, narrow);
  }
}

class CopyChannelLinkButton extends ActionSheetMenuItemButton {
  const CopyChannelLinkButton({
    super.key,
    required this.channelId,
    required super.pageContext,
  });

  final int channelId;

  @override
  IconData get icon => ZulipIcons.link;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionCopyChannelLink;
  }

  @override
  void onPressed() async {
    final localizations = ZulipLocalizations.of(pageContext);
    final store = PerAccountStoreWidget.of(pageContext);

    PlatformActions.copyWithPopup(context: pageContext,
      successContent: Text(localizations.successChannelLinkCopied),
      data: ClipboardData(text: narrowLink(store, ChannelNarrow(channelId)).toString()));
  }
}

/// Show a sheet of actions you can take on a topic.
///
/// Needs a [PageRoot] ancestor.
///
/// The API request for resolving/unresolving a topic needs a message ID.
/// If [someMessageIdInTopic] is null, the button for that will be absent.
void showTopicActionSheet(BuildContext context, {
  required int channelId,
  required TopicName topic,
  required int? someMessageIdInTopic,
}) {
  final pageContext = PageRoot.contextOf(context);

  final store = PerAccountStoreWidget.of(pageContext);
  final subscription = store.subscriptions[channelId];

  final optionButtons = <ActionSheetMenuItemButton>[];

  // TODO(server-7): simplify this condition away
  final supportsUnmutingTopics = store.zulipFeatureLevel >= 170;
  // TODO(server-8): simplify this condition away
  final supportsFollowingTopics = store.zulipFeatureLevel >= 219;

  final visibilityOptions = <UserTopicVisibilityPolicy>[];
  final visibilityPolicy = store.topicVisibilityPolicy(channelId, topic);
  if (subscription == null) {
    // Not subscribed to the channel; there is no user topic change to be made.
  } else if (!subscription.isMuted) {
    // Channel is subscribed and not muted.
    switch (visibilityPolicy) {
      case UserTopicVisibilityPolicy.muted:
        visibilityOptions.add(UserTopicVisibilityPolicy.none);
        if (supportsFollowingTopics) {
          visibilityOptions.add(UserTopicVisibilityPolicy.followed);
        }
      case UserTopicVisibilityPolicy.none:
      case UserTopicVisibilityPolicy.unmuted:
        visibilityOptions.add(UserTopicVisibilityPolicy.muted);
        if (supportsFollowingTopics) {
          visibilityOptions.add(UserTopicVisibilityPolicy.followed);
        }
      case UserTopicVisibilityPolicy.followed:
        visibilityOptions.add(UserTopicVisibilityPolicy.muted);
        if (supportsFollowingTopics) {
          visibilityOptions.add(UserTopicVisibilityPolicy.none);
        }
      case UserTopicVisibilityPolicy.unknown:
        // TODO(#1074): This should be unreachable as we keep `unknown` out of
        //   our data structures.
        assert(false);
    }
  } else {
    // Channel is muted.
    if (supportsUnmutingTopics) {
      switch (visibilityPolicy) {
        case UserTopicVisibilityPolicy.none:
        case UserTopicVisibilityPolicy.muted:
          visibilityOptions.add(UserTopicVisibilityPolicy.unmuted);
          if (supportsFollowingTopics) {
            visibilityOptions.add(UserTopicVisibilityPolicy.followed);
          }
        case UserTopicVisibilityPolicy.unmuted:
          visibilityOptions.add(UserTopicVisibilityPolicy.muted);
          if (supportsFollowingTopics) {
            visibilityOptions.add(UserTopicVisibilityPolicy.followed);
          }
        case UserTopicVisibilityPolicy.followed:
          visibilityOptions.add(UserTopicVisibilityPolicy.muted);
          if (supportsFollowingTopics) {
            visibilityOptions.add(UserTopicVisibilityPolicy.none);
          }
        case UserTopicVisibilityPolicy.unknown:
          // TODO(#1074): This should be unreachable as we keep `unknown` out of
          //   our data structures.
          assert(false);
      }
    }
  }
  optionButtons.addAll(visibilityOptions.map((to) {
    return UserTopicUpdateButton(
      currentVisibilityPolicy: visibilityPolicy,
      newVisibilityPolicy: to,
      narrow: TopicNarrow(channelId, topic),
      pageContext: pageContext);
  }));

  // TODO: check for other cases that may disallow this action (e.g.: time
  //   limit for editing topics).
  if (someMessageIdInTopic != null && topic.displayName != null) {
    optionButtons.add(ResolveUnresolveButton(pageContext: pageContext,
      topic: topic,
      someMessageIdInTopic: someMessageIdInTopic));
  }

  final unreadCount = store.unreads.countInTopicNarrow(channelId, topic);
  if (unreadCount > 0) {
    optionButtons.add(MarkTopicAsReadButton(
      channelId: channelId,
      topic: topic,
      pageContext: context));
  }

  optionButtons.add(CopyTopicLinkButton(
    narrow: TopicNarrow(channelId, topic, with_: someMessageIdInTopic),
    pageContext: context));

  _showActionSheet(pageContext, optionButtons: optionButtons);
}

class UserTopicUpdateButton extends ActionSheetMenuItemButton {
  const UserTopicUpdateButton({
    super.key,
    required this.currentVisibilityPolicy,
    required this.newVisibilityPolicy,
    required this.narrow,
    required super.pageContext,
  });

  final UserTopicVisibilityPolicy currentVisibilityPolicy;
  final UserTopicVisibilityPolicy newVisibilityPolicy;
  final TopicNarrow narrow;

  @override IconData get icon {
    switch (newVisibilityPolicy) {
      case UserTopicVisibilityPolicy.none:
        return ZulipIcons.inherit;
      case UserTopicVisibilityPolicy.muted:
        return ZulipIcons.mute;
      case UserTopicVisibilityPolicy.unmuted:
        return ZulipIcons.unmute;
      case UserTopicVisibilityPolicy.followed:
        return ZulipIcons.follow;
      case UserTopicVisibilityPolicy.unknown:
        // TODO(#1074): This should be unreachable as we keep `unknown` out of
        //   our data structures.
        assert(false);
        return ZulipIcons.inherit;
    }
  }

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    switch ((currentVisibilityPolicy, newVisibilityPolicy)) {
      case (UserTopicVisibilityPolicy.muted, UserTopicVisibilityPolicy.none):
        return zulipLocalizations.actionSheetOptionUnmuteTopic;
      case (UserTopicVisibilityPolicy.followed, UserTopicVisibilityPolicy.none):
        return zulipLocalizations.actionSheetOptionUnfollowTopic;

      case (_, UserTopicVisibilityPolicy.muted):
        return zulipLocalizations.actionSheetOptionMuteTopic;
      case (_, UserTopicVisibilityPolicy.unmuted):
        return zulipLocalizations.actionSheetOptionUnmuteTopic;
      case (_, UserTopicVisibilityPolicy.followed):
        return zulipLocalizations.actionSheetOptionFollowTopic;

      case (_, UserTopicVisibilityPolicy.none):
        // This is unexpected because `UserTopicVisibilityPolicy.muted` and
        // `UserTopicVisibilityPolicy.followed` (handled in separate `case`'s)
        // are the only expected `currentVisibilityPolicy`
        // when `newVisibilityPolicy` is `UserTopicVisibilityPolicy.none`.
        assert(false);
        return '';

      case (_, UserTopicVisibilityPolicy.unknown):
        // This case is unreachable (or should be) because we keep `unknown` out
        // of our data structures. We plan to remove the `unknown` case in #1074.
        assert(false);
        return '';
    }
  }

  String _errorTitle(ZulipLocalizations zulipLocalizations) {
    switch ((currentVisibilityPolicy, newVisibilityPolicy)) {
      case (UserTopicVisibilityPolicy.muted, UserTopicVisibilityPolicy.none):
        return zulipLocalizations.errorUnmuteTopicFailed;
      case (UserTopicVisibilityPolicy.followed, UserTopicVisibilityPolicy.none):
        return zulipLocalizations.errorUnfollowTopicFailed;

      case (_, UserTopicVisibilityPolicy.muted):
        return zulipLocalizations.errorMuteTopicFailed;
      case (_, UserTopicVisibilityPolicy.unmuted):
        return zulipLocalizations.errorUnmuteTopicFailed;
      case (_, UserTopicVisibilityPolicy.followed):
        return zulipLocalizations.errorFollowTopicFailed;

      case (_, UserTopicVisibilityPolicy.none):
        // This is unexpected because `UserTopicVisibilityPolicy.muted` and
        // `UserTopicVisibilityPolicy.followed` (handled in separate `case`'s)
        // are the only expected `currentVisibilityPolicy`
        // when `newVisibilityPolicy` is `UserTopicVisibilityPolicy.none`.
        assert(false);
        return '';

      case (_, UserTopicVisibilityPolicy.unknown):
        // This case is unreachable (or should be) because we keep `unknown` out
        // of our data structures. We plan to remove the `unknown` case in #1074.
        assert(false);
        return '';
    }
  }

  @override void onPressed() async {
    try {
      await updateUserTopicCompat(
        PerAccountStoreWidget.of(pageContext).connection,
        streamId: narrow.streamId,
        topic: narrow.topic,
        visibilityPolicy: newVisibilityPolicy);
    } catch (e) {
      if (!pageContext.mounted) return;

      String? errorMessage;

      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO(#741) specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      final zulipLocalizations = ZulipLocalizations.of(pageContext);
      showErrorDialog(context: pageContext,
        title: _errorTitle(zulipLocalizations), message: errorMessage);
    }
  }
}

class ResolveUnresolveButton extends ActionSheetMenuItemButton {
  ResolveUnresolveButton({
    super.key,
    required this.topic,
    required this.someMessageIdInTopic,
    required super.pageContext,
  }) : _actionIsResolve = !topic.isResolved;

  /// The topic that the action sheet was opened for.
  ///
  /// There might not currently be any messages with this topic;
  /// see dartdoc of [ActionSheetMenuItemButton].
  final TopicName topic;

  /// The message ID that was passed when opening the action sheet.
  ///
  /// The message with this ID might currently not exist,
  /// or might exist with a different topic;
  /// see dartdoc of [ActionSheetMenuItemButton].
  final int someMessageIdInTopic;

  final bool _actionIsResolve;

  @override
  IconData get icon => _actionIsResolve ? ZulipIcons.check : ZulipIcons.check_remove;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return _actionIsResolve
      ? zulipLocalizations.actionSheetOptionResolveTopic
      : zulipLocalizations.actionSheetOptionUnresolveTopic;
  }

  @override void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final store = PerAccountStoreWidget.of(pageContext);

    // We *could* check here if the topic has changed since the action sheet was
    // opened (see dartdoc of [ActionSheetMenuItemButton]) and abort if so.
    // We simplify by not doing so.
    // There's already an inherent race that that check wouldn't help with:
    // when you tap the button, an intervening topic change may already have
    // happened, just not reached us in an event yet.
    // Discussion, including about what web does:
    //   https://github.com/zulip/zulip-flutter/pull/1301#discussion_r1936181560

    try {
      await updateMessage(store.connection,
        messageId: someMessageIdInTopic,
        topic: _actionIsResolve ? topic.resolve() : topic.unresolve(),
        propagateMode: PropagateMode.changeAll,
        sendNotificationToOldThread: false,
        sendNotificationToNewThread: true,
      );
    } catch (e) {
      if (!pageContext.mounted) return;

      String? errorMessage;
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO(#741) specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      final title = _actionIsResolve
        ? zulipLocalizations.errorResolveTopicFailedTitle
        : zulipLocalizations.errorUnresolveTopicFailedTitle;
      showErrorDialog(context: pageContext, title: title, message: errorMessage);
    }
  }
}

class MarkTopicAsReadButton extends ActionSheetMenuItemButton {
  const MarkTopicAsReadButton({
    super.key,
    required this.channelId,
    required this.topic,
    required super.pageContext,
  });

  final int channelId;
  final TopicName topic;

  @override IconData get icon => ZulipIcons.message_checked;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionMarkTopicAsRead;
  }

  @override void onPressed() async {
    await ZulipAction.markNarrowAsRead(pageContext, TopicNarrow(channelId, topic));
  }
}

class CopyTopicLinkButton extends ActionSheetMenuItemButton {
  const CopyTopicLinkButton({
    super.key,
    required this.narrow,
    required super.pageContext,
  });

  final TopicNarrow narrow;

  @override IconData get icon => ZulipIcons.link;

  @override
  String label(ZulipLocalizations localizations) {
    return localizations.actionSheetOptionCopyTopicLink;
  }

  @override void onPressed() async {
    final localizations = ZulipLocalizations.of(pageContext);
    final store = PerAccountStoreWidget.of(pageContext);

    PlatformActions.copyWithPopup(context: pageContext,
      successContent: Text(localizations.successTopicLinkCopied),
      data: ClipboardData(text: narrowLink(store, narrow).toString()));
  }
}

/// Show a sheet of actions you can take on a message in the message list.
///
/// Must have a [MessageListPage] ancestor.
void showMessageActionSheet({required BuildContext context, required Message message}) {
  final pageContext = PageRoot.contextOf(context);
  final store = PerAccountStoreWidget.of(pageContext);

  final popularEmojiLoaded = store.popularEmojiCandidates().isNotEmpty;

  // The UI that's conditioned on this won't live-update during this appearance
  // of the action sheet (we avoid calling composeBoxControllerOf in a build
  // method; see its doc).
  // So we rely on the fact that isComposeBoxOffered for any given message list
  // will be constant through the page's life.
  final messageListPage = MessageListPage.ancestorOf(pageContext);
  final isComposeBoxOffered = messageListPage.composeBoxState != null;

  final isMessageRead = message.flags.contains(MessageFlag.read);
  final markAsUnreadSupported = store.zulipFeatureLevel >= 155; // TODO(server-6)
  final showMarkAsUnreadButton = markAsUnreadSupported && isMessageRead;

  final isSenderMuted = store.isUserMuted(message.senderId);

  final optionButtons = [
    if (popularEmojiLoaded)
      ReactionButtons(message: message, pageContext: pageContext),
    StarButton(message: message, pageContext: pageContext),
    if (isComposeBoxOffered)
      QuoteAndReplyButton(message: message, pageContext: pageContext),
    if (showMarkAsUnreadButton)
      MarkAsUnreadButton(message: message, pageContext: pageContext),
    if (isSenderMuted)
      // The message must have been revealed in order to open this action sheet.
      UnrevealMutedMessageButton(message: message, pageContext: pageContext),
    CopyMessageTextButton(message: message, pageContext: pageContext),
    CopyMessageLinkButton(message: message, pageContext: pageContext),
    ShareButton(message: message, pageContext: pageContext),
    if (_getShouldShowEditButton(pageContext, message))
      EditButton(message: message, pageContext: pageContext),
  ];

  _showActionSheet(pageContext,
    optionButtons: optionButtons,
    header: _MessageActionSheetHeader(message: message));
}

class _MessageActionSheetHeader extends StatelessWidget {
  const _MessageActionSheetHeader({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    // TODO this seems to lose the hero animation when opening an image;
    //   investigate.
    // TODO should we close the sheet before opening a narrow link?
    //   On popping the pushed narrow route, the sheet is still open.

    return Container(
      // TODO(#647) use different color for highlighted messages
      // TODO(#681) use different color for DM messages
      color: designVariables.bgMessageRegular,
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        spacing: 4,
        children: [
          SenderRow(message: message,
            timestampStyle: MessageTimestampStyle.full),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // TODO(#10) offer text selection; the Figma asks for it here:
            //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3483-30210&m=dev
            child: MessageContent(message: message, content: parseMessageContent(message))),
        ]));
  }
}

abstract class MessageActionSheetMenuItemButton extends ActionSheetMenuItemButton {
  MessageActionSheetMenuItemButton({
    super.key,
    required this.message,
    required super.pageContext,
  }) : assert(pageContext.findAncestorWidgetOfExactType<MessageListPage>() != null);

  final Message message;
}

bool _getShouldShowEditButton(BuildContext pageContext, Message message) {
  final store = PerAccountStoreWidget.of(pageContext);

  final messageListPage = MessageListPage.ancestorOf(pageContext);
  final composeBoxState = messageListPage.composeBoxState;
  final isComposeBoxOffered = composeBoxState != null;
  final composeBoxController = composeBoxState?.controller;

  final editMessageErrorStatus = store.getEditMessageErrorStatus(message.id);
  final editMessageInProgress =
    // The compose box is in edit-message mode, with Cancel/Save instead of Send.
    composeBoxController is EditMessageComposeBoxController
    // An edit request is in progress or the error state.
    || editMessageErrorStatus != null;

  final now = ZulipBinding.instance.utcNow().millisecondsSinceEpoch ~/ 1000;
  final editLimit = store.realmMessageContentEditLimitSeconds;
  final outsideEditLimit =
    editLimit != null
    && editLimit != 0 // TODO(server-6) remove (pre-FL 138, 0 represents no limit)
    && now - message.timestamp > editLimit;

  return message.senderId == store.selfUserId
    && isComposeBoxOffered
    && store.realmAllowMessageEditing
    && !outsideEditLimit
    && !editMessageInProgress
    && message.poll == null; // messages with polls cannot be edited
}

class ReactionButtons extends StatelessWidget {
  const ReactionButtons({
    super.key,
    required this.message,
    required this.pageContext,
  });

  final Message message;

  /// A context within the [MessageListPage] this action sheet was
  /// triggered from.
  final BuildContext pageContext;

  void _handleTapReaction({
    required EmojiCandidate emoji,
    required bool isSelfVoted,
  }) {
    // Dismiss the enclosing action sheet immediately,
    // for swift UI feedback that the user's selection was received.
    Navigator.pop(pageContext);

    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    doAddOrRemoveReaction(
      context: pageContext,
      doRemoveReaction: isSelfVoted,
      messageId: message.id,
      emoji: emoji,
      errorDialogTitle: isSelfVoted
        ? zulipLocalizations.errorReactionRemovingFailedTitle
        : zulipLocalizations.errorReactionAddingFailedTitle);
  }

  void _handleTapMore() async {
    // TODO(design): have emoji picker slide in from right and push
    //   action sheet off to the left

    // Dismiss current action sheet before opening emoji picker sheet.
    Navigator.of(pageContext).pop();

    final emoji = await showEmojiPickerSheet(pageContext: pageContext);
    if (emoji == null || !pageContext.mounted) return;
    unawaited(doAddOrRemoveReaction(
      context: pageContext,
      doRemoveReaction: false,
      messageId: message.id,
      emoji: emoji,
      errorDialogTitle:
        ZulipLocalizations.of(pageContext).errorReactionAddingFailedTitle));
  }

  Widget _buildButton({
    required BuildContext context,
    required EmojiCandidate emoji,
    required bool isSelfVoted,
    required bool isFirst,
  }) {
    final designVariables = DesignVariables.of(context);
    return Flexible(child: InkWell(
      onTap: () => _handleTapReaction(emoji: emoji, isSelfVoted: isSelfVoted),
      splashFactory: NoSplash.splashFactory,
      borderRadius: isFirst
        ? const BorderRadius.only(topLeft: Radius.circular(7))
        : null,
      overlayColor: WidgetStateColor.resolveWith((states) =>
        states.any((e) => e == WidgetState.pressed)
          ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
          : Colors.transparent),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        alignment: Alignment.center,
        color: isSelfVoted
          ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
          : null,
        child: UnicodeEmojiWidget(
          emojiDisplay: emoji.emojiDisplay as UnicodeEmojiDisplay,
          size: 24))));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(pageContext);
    final popularEmojiCandidates = store.popularEmojiCandidates();
    assert(popularEmojiCandidates.every(
      (emoji) => emoji.emojiType == ReactionType.unicodeEmoji));
    // (if this is empty, the widget isn't built in the first place)
    assert(popularEmojiCandidates.isNotEmpty);
    // UI not designed to handle more than 6 popular emoji.
    // (We might have fewer if ServerEmojiData is lacking expected data,
    // but that looks fine in manual testing, even when there's just one.)
    assert(popularEmojiCandidates.length <= 6);

    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    bool hasSelfVote(EmojiCandidate emoji) {
      return message.reactions?.aggregated.any((reactionWithVotes) {
        return reactionWithVotes.reactionType == ReactionType.unicodeEmoji
          && reactionWithVotes.emojiCode == emoji.emojiCode
          && reactionWithVotes.userIds.contains(store.selfUserId);
      }) ?? false;
    }

    return Container(
      decoration: BoxDecoration(
        color: designVariables.contextMenuItemBg.withFadedAlpha(0.12)),
      child: Row(children: [
        Flexible(child: Row(spacing: 1, children: List.unmodifiable(
          popularEmojiCandidates.mapIndexed((index, emoji) =>
            _buildButton(
              context: context,
              emoji: emoji,
              isSelfVoted: hasSelfVote(emoji),
              isFirst: index == 0))))),
        InkWell(
          onTap: _handleTapMore,
          splashFactory: NoSplash.splashFactory,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(7)),
          overlayColor: WidgetStateColor.resolveWith((states) =>
            states.any((e) => e == WidgetState.pressed)
              ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
              : Colors.transparent),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
            child: Row(children: [
              Text(zulipLocalizations.emojiReactionsMore,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: designVariables.contextMenuItemText,
                  fontSize: 14,
                ).merge(weightVariableTextStyle(context, wght: 600))),
              Icon(ZulipIcons.chevron_right,
                color: designVariables.contextMenuItemText,
                size: 24),
            ]),
          )),
      ]),
    );
  }
}

class StarButton extends MessageActionSheetMenuItemButton {
  StarButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => _isStarred ? ZulipIcons.star_filled : ZulipIcons.star;

  bool get _isStarred => message.flags.contains(MessageFlag.starred);

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return _isStarred
      ? zulipLocalizations.actionSheetOptionUnstarMessage
      : zulipLocalizations.actionSheetOptionStarMessage;
  }

  @override void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final op = message.flags.contains(MessageFlag.starred)
      ? UpdateMessageFlagsOp.remove
      : UpdateMessageFlagsOp.add;

    try {
      final connection = PerAccountStoreWidget.of(pageContext).connection;
      await updateMessageFlags(connection, messages: [message.id],
        op: op, flag: MessageFlag.starred);
    } catch (e) {
      if (!pageContext.mounted) return;

      String? errorMessage;
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      showErrorDialog(context: pageContext,
        title: switch(op) {
          UpdateMessageFlagsOp.remove => zulipLocalizations.errorUnstarMessageFailedTitle,
          UpdateMessageFlagsOp.add    => zulipLocalizations.errorStarMessageFailedTitle,
        }, message: errorMessage);
    }
  }
}

class QuoteAndReplyButton extends MessageActionSheetMenuItemButton {
  QuoteAndReplyButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => ZulipIcons.format_quote;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionQuoteMessage;
  }

  @override void onPressed() async {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    final message = this.message;

    var composeBoxController = findMessageListPage().composeBoxState?.controller;
    // The compose box doesn't null out its controller; it's either always null
    // (e.g. in Combined Feed) or always non-null; it can't have been nulled out
    // after the action sheet opened.
    composeBoxController!;
    if (
      composeBoxController is StreamComposeBoxController
      && composeBoxController.topic.textNormalized == kNoTopicTopic
      && message is StreamMessage
    ) {
      composeBoxController.topic.setTopic(message.topic);
    }

    // This inserts a "[Quoting…]" placeholder into the content input,
    // giving the user a form of progress feedback.
    final tag = composeBoxController.content
      .registerQuoteAndReplyStart(
        zulipLocalizations,
        PerAccountStoreWidget.of(pageContext),
        message: message,
      );

    final rawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorQuotationFailed,
    );

    if (!pageContext.mounted) return;

    composeBoxController = findMessageListPage().composeBoxState?.controller;
    // The compose box doesn't null out its controller; it's either always null
    // (e.g. in Combined Feed) or always non-null; it can't have been nulled out
    // during the raw-content request.
    composeBoxController!.content
      .registerQuoteAndReplyEnd(PerAccountStoreWidget.of(pageContext), tag,
        message: message,
        rawContent: rawContent,
      );
    if (!composeBoxController.contentFocusNode.hasFocus) {
      composeBoxController.contentFocusNode.requestFocus();
    }
  }
}

class MarkAsUnreadButton extends MessageActionSheetMenuItemButton {
  MarkAsUnreadButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => Icons.mark_chat_unread_outlined;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionMarkAsUnread;
  }

  @override void onPressed() async {
    final messageListPage = findMessageListPage();
    unawaited(ZulipAction.markNarrowAsUnreadFromMessage(pageContext,
      message, messageListPage.narrow));
    // TODO should we alert the user about this change somehow? A snackbar?
    messageListPage.markReadOnScroll = false;
  }
}

class UnrevealMutedMessageButton extends MessageActionSheetMenuItemButton {
  UnrevealMutedMessageButton({
    super.key,
    required super.message,
    required super.pageContext,
  });

  @override
  IconData get icon => ZulipIcons.eye_off;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionHideMutedMessage;
  }

  @override
  void onPressed() {
    // The message should have been revealed in order to reach this action sheet.
    assert(MessageListPage.maybeRevealedMutedMessagesOf(pageContext)!
      .isMutedMessageRevealed(message.id));
    findMessageListPage().unrevealMutedMessage(message.id);
  }
}

class CopyMessageTextButton extends MessageActionSheetMenuItemButton {
  CopyMessageTextButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => ZulipIcons.copy;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionCopyMessageText;
  }

  @override void onPressed() async {
    // This action doesn't show request progress.
    // But hopefully it won't take long at all,
    // and [ZulipAction.fetchRawContentWithFeedback] has a TODO
    // for giving feedback if it does.

    final zulipLocalizations = ZulipLocalizations.of(pageContext);

    final rawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorCopyingFailed,
    );

    if (rawContent == null) return;

    if (!pageContext.mounted) return;

    PlatformActions.copyWithPopup(context: pageContext,
      successContent: Text(zulipLocalizations.successMessageTextCopied),
      data: ClipboardData(text: rawContent));
  }
}

class CopyMessageLinkButton extends MessageActionSheetMenuItemButton {
  CopyMessageLinkButton({super.key, required super.message, required super.pageContext});

  @override IconData get icon => ZulipIcons.link;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionCopyMessageLink;
  }

  @override void onPressed() {
    final zulipLocalizations = ZulipLocalizations.of(pageContext);

    final store = PerAccountStoreWidget.of(pageContext);
    final messageLink = narrowLink(
      store,
      SendableNarrow.ofMessage(message, selfUserId: store.selfUserId),
      nearMessageId: message.id,
    );

    PlatformActions.copyWithPopup(context: pageContext,
      successContent: Text(zulipLocalizations.successMessageLinkCopied),
      data: ClipboardData(text: messageLink.toString()));
  }
}

class ShareButton extends MessageActionSheetMenuItemButton {
  ShareButton({super.key, required super.message, required super.pageContext});

  @override
  IconData get icon => defaultTargetPlatform == TargetPlatform.iOS
    ? ZulipIcons.share_ios
    : ZulipIcons.share;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.actionSheetOptionShare;
  }

  @override void onPressed() async {
    // TODO(#591): Fix iOS bug where if the keyboard was open before the call
    //   to `showMessageActionSheet`, it reappears briefly between
    //   the `pop` of the action sheet and the appearance of the share sheet.
    //
    //   (Alternatively we could delay the [NavigatorState.pop] that
    //   dismisses the action sheet until after the sharing Future settles
    //   with [ShareResultStatus.success].  But on iOS one gets impatient with
    //   how slowly our action sheet dismisses in that case.)

    final zulipLocalizations = ZulipLocalizations.of(pageContext);

    final rawContent = await ZulipAction.fetchRawContentWithFeedback(
      context: pageContext,
      messageId: message.id,
      errorDialogTitle: zulipLocalizations.errorSharingFailed,
    );

    if (rawContent == null) return;

    if (!pageContext.mounted) return;

    // TODO: to support iPads, we're asked to give a
    //   `sharePositionOrigin` param, or risk crashing / hanging:
    //     https://pub.dev/packages/share_plus#ipad
    //   Perhaps a wart in the API; discussion:
    //     https://github.com/zulip/zulip-flutter/pull/12#discussion_r1130146231
    final result =
      await SharePlus.instance.share(ShareParams(text: rawContent));

    switch (result.status) {
      // The plugin isn't very helpful: "The status can not be determined".
      // Until we learn otherwise, assume something wrong happened.
      case ShareResultStatus.unavailable:
        if (!pageContext.mounted) return;
        showErrorDialog(context: pageContext,
          title: zulipLocalizations.errorSharingFailed);
      case ShareResultStatus.success:
      case ShareResultStatus.dismissed:
        // nothing to do
    }
  }
}

class EditButton extends MessageActionSheetMenuItemButton {
  EditButton({super.key, required super.message, required super.pageContext});

  @override
  IconData get icon => ZulipIcons.edit;

  @override
  String label(ZulipLocalizations zulipLocalizations) =>
    zulipLocalizations.actionSheetOptionEditMessage;

  @override void onPressed() async {
    final composeBoxState = findMessageListPage().composeBoxState;
    if (composeBoxState == null) {
      throw StateError('Compose box unexpectedly absent when edit-message button pressed');
    }
    composeBoxState.startEditInteraction(message.id);
  }
}
