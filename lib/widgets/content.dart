import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart' as intl;

import '../api/core.dart';
import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/content.dart';
import '../model/internal_link.dart';
import 'actions.dart';
import 'code_block.dart';
import 'dialog.dart';
import 'icons.dart';
import 'inset_shadow.dart';
import 'katex.dart';
import 'lightbox.dart';
import 'message_list.dart';
import 'poll.dart';
import 'scrolling.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

/// A central place for styles for Zulip content (rendered Zulip Markdown).
///
/// These styles will animate on theme changes (with help from [lerp]),
/// so styles that differ between light and dark theme belong here.
///
/// Styles also belong here if we want to centralize computing them,
/// for performance. (The message list is particularly performance-sensitive.)
///
/// Content elements are assumed to be painted on a theme-appropriate
/// background. For what this is in the message list, see
/// widgets/message_list.dart.
class ContentTheme extends ThemeExtension<ContentTheme> {
  factory ContentTheme.light(BuildContext context) {
    return ContentTheme._(
      colorCodeBlockBackground: const HSLColor.fromAHSL(0.04, 0, 0, 0).toColor(),
      colorDirectMentionBackground: const HSLColor.fromAHSL(0.2, 240, 0.7, 0.7).toColor(),
      colorGlobalTimeBackground: const HSLColor.fromAHSL(1, 0, 0, 0.93).toColor(),
      colorGlobalTimeBorder: const HSLColor.fromAHSL(1, 0, 0, 0.8).toColor(),
      colorLink: const HSLColor.fromAHSL(1, 200, 1, 0.4).toColor(),
      colorMathBlockBorder: const HSLColor.fromAHSL(0.15, 240, 0.8, 0.5).toColor(),
      colorMessageMediaContainerBackground: const Color.fromRGBO(0, 0, 0, 0.03),
      colorPollNames: const HSLColor.fromAHSL(1, 0, 0, .45).toColor(),
      colorPollVoteCountBackground: const HSLColor.fromAHSL(1, 0, 0, 1).toColor(),
      colorPollVoteCountBorder: const HSLColor.fromAHSL(1, 156, 0.28, 0.7).toColor(),
      colorPollVoteCountText: const HSLColor.fromAHSL(1, 156, 0.41, 0.4).toColor(),
      colorTableCellBorder: const HSLColor.fromAHSL(1, 0, 0, 0.80).toColor(),
      colorTableHeaderBackground: const HSLColor.fromAHSL(1, 0, 0, 0.93).toColor(),
      colorThematicBreak: const HSLColor.fromAHSL(1, 0, 0, .87).toColor(),
      textStylePlainParagraph: _plainParagraphCommon(context).copyWith(
        color: const HSLColor.fromAHSL(1, 0, 0, 0.15).toColor(),
        debugLabel: 'ContentTheme.textStylePlainParagraph'),
      textStyleEmoji: TextStyle(
        fontFamily: emojiFontFamily, fontFamilyFallback: const []),
      codeBlockTextStyles: CodeBlockTextStyles.light(context),
      textStyleError: const TextStyle(fontSize: kBaseFontSize, color: Colors.red)
        .merge(weightVariableTextStyle(context, wght: 700)),
      textStyleErrorCode: kMonospaceTextStyle
        .merge(const TextStyle(fontSize: kBaseFontSize, color: Colors.red)),
      textStyleInlineCode: kMonospaceTextStyle.merge(TextStyle(
        backgroundColor: const HSLColor.fromAHSL(0.06, 0, 0, 0).toColor())),
      textStyleInlineMath: kMonospaceTextStyle.merge(TextStyle(
        // TODO(#46) this won't be needed
        backgroundColor: const HSLColor.fromAHSL(1, 240, 0.4, 0.93).toColor())),
    );
  }

  factory ContentTheme.dark(BuildContext context) {
    return ContentTheme._(
      colorCodeBlockBackground: const HSLColor.fromAHSL(0.04, 0, 0, 1).toColor(),
      colorDirectMentionBackground: const HSLColor.fromAHSL(0.25, 240, 0.52, 0.6).toColor(),
      colorGlobalTimeBackground: const HSLColor.fromAHSL(0.2, 0, 0, 0).toColor(),
      colorGlobalTimeBorder: const HSLColor.fromAHSL(0.4, 0, 0, 0).toColor(),
      colorLink: const HSLColor.fromAHSL(1, 200, 1, 0.4).toColor(), // the same as light in Web
      colorMathBlockBorder: const HSLColor.fromAHSL(1, 240, 0.4, 0.4).toColor(),
      colorMessageMediaContainerBackground: const HSLColor.fromAHSL(0.03, 0, 0, 1).toColor(),
      colorPollNames: const HSLColor.fromAHSL(1, 236, .15, .7).toColor(),
      colorPollVoteCountBackground: const HSLColor.fromAHSL(0.2, 0, 0, 0).toColor(),
      colorPollVoteCountBorder: const HSLColor.fromAHSL(1, 185, 0.35, 0.35).toColor(),
      colorPollVoteCountText: const HSLColor.fromAHSL(1, 185, 0.35, 0.65).toColor(),
      colorTableCellBorder: const HSLColor.fromAHSL(1, 0, 0, 0.33).toColor(),
      colorTableHeaderBackground: const HSLColor.fromAHSL(0.5, 0, 0, 0).toColor(),
      colorThematicBreak: const HSLColor.fromAHSL(1, 0, 0, .87).toColor().withValues(alpha: 0.2),
      textStylePlainParagraph: _plainParagraphCommon(context).copyWith(
        color: const HSLColor.fromAHSL(1, 0, 0, 0.85).toColor(),
        debugLabel: 'ContentTheme.textStylePlainParagraph'),
      textStyleEmoji: TextStyle(
        fontFamily: emojiFontFamily, fontFamilyFallback: const []),
      codeBlockTextStyles: CodeBlockTextStyles.dark(context),
      textStyleError: const TextStyle(fontSize: kBaseFontSize, color: Colors.red)
        .merge(weightVariableTextStyle(context, wght: 700)),
      textStyleErrorCode: kMonospaceTextStyle
        .merge(const TextStyle(fontSize: kBaseFontSize, color: Colors.red)),
      textStyleInlineCode: kMonospaceTextStyle.merge(TextStyle(
        backgroundColor: const HSLColor.fromAHSL(0.08, 0, 0, 1).toColor())),
      textStyleInlineMath: kMonospaceTextStyle.merge(TextStyle(
        // TODO(#46) this won't be needed
        backgroundColor: const HSLColor.fromAHSL(1, 240, 0.4, 0.4).toColor())),
    );
  }

  ContentTheme._({
    required this.colorCodeBlockBackground,
    required this.colorDirectMentionBackground,
    required this.colorGlobalTimeBackground,
    required this.colorGlobalTimeBorder,
    required this.colorLink,
    required this.colorMathBlockBorder,
    required this.colorMessageMediaContainerBackground,
    required this.colorPollNames,
    required this.colorPollVoteCountBackground,
    required this.colorPollVoteCountBorder,
    required this.colorPollVoteCountText,
    required this.colorTableCellBorder,
    required this.colorTableHeaderBackground,
    required this.colorThematicBreak,
    required this.textStylePlainParagraph,
    required this.textStyleEmoji,
    required this.codeBlockTextStyles,
    required this.textStyleError,
    required this.textStyleErrorCode,
    required this.textStyleInlineCode,
    required this.textStyleInlineMath,
  });

  /// The [ContentTheme] from the context's active theme.
  ///
  /// The [ThemeData] must include [ContentTheme] in [ThemeData.extensions].
  static ContentTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<ContentTheme>();
    assert(extension != null);
    return extension!;
  }

  final Color colorCodeBlockBackground;
  final Color colorDirectMentionBackground;
  final Color colorGlobalTimeBackground;
  final Color colorGlobalTimeBorder;
  final Color colorLink;
  final Color colorMathBlockBorder; // TODO(#46) this won't be needed
  final Color colorMessageMediaContainerBackground;
  final Color colorPollNames;
  final Color colorPollVoteCountBackground;
  final Color colorPollVoteCountBorder;
  final Color colorPollVoteCountText;
  final Color colorTableCellBorder;
  final Color colorTableHeaderBackground;
  final Color colorThematicBreak;

  /// The complete [TextStyle] we use for plain, unstyled paragraphs.
  ///
  /// Also the base style that all other text content should inherit from.
  ///
  /// This is the complete style for plain paragraphs. Plain-paragraph content
  /// should not need styles from other sources, such as Material defaults.
  final TextStyle textStylePlainParagraph;

  /// The [TextStyle] to use for Unicode emoji.
  final TextStyle textStyleEmoji;

  final CodeBlockTextStyles codeBlockTextStyles;
  final TextStyle textStyleError;
  final TextStyle textStyleErrorCode;

  /// The [TextStyle] for inline code, excluding font-size adjustment.
  ///
  /// Inline code should use this and also apply [kInlineCodeFontSizeFactor]
  /// to the font size of the surrounding text
  /// (which might be a Paragraph, a Heading, etc.).
  final TextStyle textStyleInlineCode;

  /// The [TextStyle] for inline math, excluding font-size adjustment.
  ///
  /// Inline math should use this and also apply [kInlineCodeFontSizeFactor]
  /// to the font size of the surrounding text
  /// (which might be a Paragraph, a Heading, etc.).
  final TextStyle textStyleInlineMath;

  /// [ContentTheme.textStylePlainParagraph] attributes independent of theme.
  static TextStyle _plainParagraphCommon(BuildContext context) => TextStyle(
    inherit: false,

    fontSize: kBaseFontSize,
    letterSpacing: 0,
    textBaseline: localizedTextBaseline(context),
    height: (22 / kBaseFontSize),
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
    fontFamily: kDefaultFontFamily,
    fontFamilyFallback: defaultFontFamilyFallback,
  )
    .merge(weightVariableTextStyle(context));

  @override
  ContentTheme copyWith({
    Color? colorCodeBlockBackground,
    Color? colorDirectMentionBackground,
    Color? colorGlobalTimeBackground,
    Color? colorGlobalTimeBorder,
    Color? colorLink,
    Color? colorMathBlockBorder,
    Color? colorMessageMediaContainerBackground,
    Color? colorPollNames,
    Color? colorPollVoteCountBackground,
    Color? colorPollVoteCountBorder,
    Color? colorPollVoteCountText,
    Color? colorTableCellBorder,
    Color? colorTableHeaderBackground,
    Color? colorThematicBreak,
    TextStyle? textStylePlainParagraph,
    TextStyle? textStyleEmoji,
    CodeBlockTextStyles? codeBlockTextStyles,
    TextStyle? textStyleError,
    TextStyle? textStyleErrorCode,
    TextStyle? textStyleInlineCode,
    TextStyle? textStyleInlineMath,
  }) {
    return ContentTheme._(
      colorCodeBlockBackground: colorCodeBlockBackground ?? this.colorCodeBlockBackground,
      colorDirectMentionBackground: colorDirectMentionBackground ?? this.colorDirectMentionBackground,
      colorGlobalTimeBackground: colorGlobalTimeBackground ?? this.colorGlobalTimeBackground,
      colorGlobalTimeBorder: colorGlobalTimeBorder ?? this.colorGlobalTimeBorder,
      colorLink: colorLink ?? this.colorLink,
      colorMathBlockBorder: colorMathBlockBorder ?? this.colorMathBlockBorder,
      colorMessageMediaContainerBackground: colorMessageMediaContainerBackground ?? this.colorMessageMediaContainerBackground,
      colorPollNames: colorPollNames ?? this.colorPollNames,
      colorPollVoteCountBackground: colorPollVoteCountBackground ?? this.colorPollVoteCountBackground,
      colorPollVoteCountBorder: colorPollVoteCountBorder ?? this.colorPollVoteCountBorder,
      colorPollVoteCountText: colorPollVoteCountText ?? this.colorPollVoteCountText,
      colorTableCellBorder: colorTableCellBorder ?? this.colorTableCellBorder,
      colorTableHeaderBackground: colorTableHeaderBackground ?? this.colorTableHeaderBackground,
      colorThematicBreak: colorThematicBreak ?? this.colorThematicBreak,
      textStylePlainParagraph: textStylePlainParagraph ?? this.textStylePlainParagraph,
      textStyleEmoji: textStyleEmoji ?? this.textStyleEmoji,
      codeBlockTextStyles: codeBlockTextStyles ?? this.codeBlockTextStyles,
      textStyleError: textStyleError ?? this.textStyleError,
      textStyleErrorCode: textStyleErrorCode ?? this.textStyleErrorCode,
      textStyleInlineCode: textStyleInlineCode ?? this.textStyleInlineCode,
      textStyleInlineMath: textStyleInlineMath ?? this.textStyleInlineMath,
    );
  }

  @override
  ContentTheme lerp(ContentTheme other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return ContentTheme._(
      colorCodeBlockBackground: Color.lerp(colorCodeBlockBackground, other.colorCodeBlockBackground, t)!,
      colorDirectMentionBackground: Color.lerp(colorDirectMentionBackground, other.colorDirectMentionBackground, t)!,
      colorGlobalTimeBackground: Color.lerp(colorGlobalTimeBackground, other.colorGlobalTimeBackground, t)!,
      colorGlobalTimeBorder: Color.lerp(colorGlobalTimeBorder, other.colorGlobalTimeBorder, t)!,
      colorLink: Color.lerp(colorLink, other.colorLink, t)!,
      colorMathBlockBorder: Color.lerp(colorMathBlockBorder, other.colorMathBlockBorder, t)!,
      colorMessageMediaContainerBackground: Color.lerp(colorMessageMediaContainerBackground, other.colorMessageMediaContainerBackground, t)!,
      colorPollNames: Color.lerp(colorPollNames, other.colorPollNames, t)!,
      colorPollVoteCountBackground: Color.lerp(colorPollVoteCountBackground, other.colorPollVoteCountBackground, t)!,
      colorPollVoteCountBorder: Color.lerp(colorPollVoteCountBorder, other.colorPollVoteCountBorder, t)!,
      colorPollVoteCountText: Color.lerp(colorPollVoteCountText, other.colorPollVoteCountText, t)!,
      colorTableCellBorder: Color.lerp(colorTableCellBorder, other.colorTableCellBorder, t)!,
      colorTableHeaderBackground: Color.lerp(colorTableHeaderBackground, other.colorTableHeaderBackground, t)!,
      colorThematicBreak: Color.lerp(colorThematicBreak, other.colorThematicBreak, t)!,
      textStylePlainParagraph: TextStyle.lerp(textStylePlainParagraph, other.textStylePlainParagraph, t)!,
      textStyleEmoji: TextStyle.lerp(textStyleEmoji, other.textStyleEmoji, t)!,
      codeBlockTextStyles: CodeBlockTextStyles.lerp(codeBlockTextStyles, other.codeBlockTextStyles, t),
      textStyleError: TextStyle.lerp(textStyleError, other.textStyleError, t)!,
      textStyleErrorCode: TextStyle.lerp(textStyleErrorCode, other.textStyleErrorCode, t)!,
      textStyleInlineCode: TextStyle.lerp(textStyleInlineCode, other.textStyleInlineCode, t)!,
      textStyleInlineMath: TextStyle.lerp(textStyleInlineMath, other.textStyleInlineMath, t)!,
    );
  }
}

/// The font size for message content in a plain unstyled paragraph.
const double kBaseFontSize = 17;

/// The entire content of a message, aka its body.
///
/// This does not include metadata like the sender's name and avatar, the time,
/// or the message's status as starred or edited.
class MessageContent extends StatelessWidget {
  const MessageContent({super.key, required this.message, required this.content});

  final Message message;
  final ZulipMessageContent content;

  @override
  Widget build(BuildContext context) {
    final content = this.content;
    return InheritedMessage(message: message,
      child: DefaultTextStyle(
        style: ContentTheme.of(context).textStylePlainParagraph,
        child: switch (content) {
          ZulipContent() => BlockContentList(nodes: content.nodes),
          PollContent()  => PollWidget(messageId: message.id, poll: content.poll),
        }));
  }
}

class InheritedMessage extends InheritedWidget {
  const InheritedMessage({super.key, required this.message, required super.child});

  final Message message;

  @override
  bool updateShouldNotify(covariant InheritedMessage oldWidget) =>
    !identical(oldWidget.message, message);

  static Message of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<InheritedMessage>();
    assert(widget != null, 'No InheritedMessage ancestor');
    return widget!.message;
  }
}

//
// Block layout.
//

/// A list of DOM nodes to display in block layout.
class BlockContentList extends StatelessWidget {
  const BlockContentList({super.key, required this.nodes});

  final List<BlockContentNode> nodes;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ...nodes.map((node) {
        return switch (node) {
          LineBreakNode() =>
            // This goes in a Column.  So to get the effect of a newline,
            // just use an empty Text.
            const Text(''),
          ThematicBreakNode() => const ThematicBreak(),
          ParagraphNode() => Paragraph(node: node),
          HeadingNode() => Heading(node: node),
          QuotationNode() => Quotation(node: node),
          ListNode() => ListNodeWidget(node: node),
          SpoilerNode() => Spoiler(node: node),
          CodeBlockNode() => CodeBlock(node: node),
          MathBlockNode() => MathBlock(node: node),
          ImageNodeList() => MessageImageList(node: node),
          ImageNode() => (){
            assert(false,
              "[ImageNode] not allowed in [BlockContentList]. "
              "It should be wrapped in [ImageNodeList]."
            );
            return MessageImage(node: node);
          }(),
          InlineVideoNode() => MessageInlineVideo(node: node),
          EmbedVideoNode() => MessageEmbedVideo(node: node),
          TableNode() => MessageTable(node: node),
          TableRowNode() => () {
            assert(false,
              "[TableRowNode] not allowed in [BlockContentList]. "
              "It should be wrapped in [TableNode]."
            );
            return const SizedBox.shrink();
          }(),
          TableCellNode() => () {
            assert(false,
              "[TableCellNode] not allowed in [BlockContentList]. "
              "It should be wrapped in [TableRowNode]."
            );
            return const SizedBox.shrink();
          }(),
          WebsitePreviewNode() => WebsitePreview(node: node),
          UnimplementedBlockContentNode() =>
            Text.rich(_errorUnimplemented(node, context: context)),
        };

      }),
    ]);
  }
}

class ThematicBreak extends StatelessWidget {
  const ThematicBreak({super.key});

  static const htmlHeight = 2.0;
  static const htmlMarginY = 20.0;

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: ContentTheme.of(context).colorThematicBreak,
      thickness: htmlHeight,
      height: 2 * htmlMarginY + htmlHeight,
    );
  }
}

class Paragraph extends StatelessWidget {
  const Paragraph({super.key, required this.node});

  final ParagraphNode node;

  @override
  Widget build(BuildContext context) {
    // Empty paragraph winds up with zero height.
    // The paragraph has vertical CSS margins, but those have no effect.
    if (node.nodes.isEmpty) return const SizedBox();

    final text = _buildBlockInlineContainer(
      node: node,
      style: DefaultTextStyle.of(context).style,
    );

    // If the paragraph didn't actually have a `p` element in the HTML,
    // then apply no margins.  (For example, these are seen in list items.)
    if (node.wasImplicit) return text;

    // For a non-empty paragraph, though — and where there was a `p` element
    // for the Zulip CSS to apply to — the margins are real.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: text);
  }
}

class Heading extends StatelessWidget {
  const Heading({super.key, required this.node});

  final HeadingNode node;

  @override
  Widget build(BuildContext context) {
    // Em-heights taken from zulip:web/styles/rendered_markdown.css .
    final emHeight = switch(node.level) {
      HeadingLevel.h1 => 1.4,
      HeadingLevel.h2 => 1.3,
      HeadingLevel.h3 => 1.2,
      HeadingLevel.h4 => 1.1,
      HeadingLevel.h5 => 1.05,
      HeadingLevel.h6 => 1.0,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 5),
      child: _buildBlockInlineContainer(
        style: TextStyle(
          fontSize: kBaseFontSize * emHeight,
          height: 1.4,
        )
          // Could set boldness relative to ambient text style, which itself
          // might be bolder than normal (e.g. in spoiler headers).
          // But this didn't seem like a clear improvement and would make inline
          // **bold** spans less distinct; discussion:
          //   https://github.com/zulip/zulip-flutter/pull/706#issuecomment-2141326257
          .merge(weightVariableTextStyle(context, wght: 600)),
        node: node));
  }
}

class Quotation extends StatelessWidget {
  const Quotation({super.key, required this.node});

  final QuotationNode node;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Container(
        padding: const EdgeInsets.only(left: 5),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 5,
              // Web has the same color in light and dark mode.
              color: const HSLColor.fromAHSL(1, 0, 0, 0.87).toColor()))),
        child: BlockContentList(nodes: node.nodes)));
  }
}

class ListNodeWidget extends StatelessWidget {
  const ListNodeWidget({super.key, required this.node});

  final ListNode node;

  @override
  Widget build(BuildContext context) {
    // TODO(#162): p+ul and p+ol interactions
    final items = List.generate(node.items.length, (index) {
      final item = node.items[index];
      String marker;
      switch (node) {
        // TODO(#161): different unordered marker styles at different levels of nesting
        //   see:
        //     https://html.spec.whatwg.org/multipage/rendering.html#lists
        //     https://www.w3.org/TR/css-counter-styles-3/#simple-symbolic
        // TODO proper alignment of unordered marker; should be "• ", one space,
        //   but that comes out too close to item; not sure what's fixing that
        //   in a browser
        case UnorderedListNode(): marker = "•   "; break;
        case OrderedListNode(:final start): marker = "${start + index}. "; break;
      }
      return TableRow(children: [
        Align(
          alignment: AlignmentDirectional.topEnd,
          child: Text(marker)),
        BlockContentList(nodes: item),
      ]);
    });

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 5),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        columnWidths: const <int, TableColumnWidth>{
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        children: items));
  }
}

class Spoiler extends StatefulWidget {
  const Spoiler({super.key, required this.node});

  final SpoilerNode node;

  @override
  State<Spoiler> createState() => _SpoilerState();
}

class _SpoilerState extends State<Spoiler> with TickerProviderStateMixin {
  bool expanded = false;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 400), vsync: this);
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      if (!expanded) {
        _controller.forward();
        expanded = true;
      } else {
        _controller.reverse();
        expanded = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final header = widget.node.header;
    final effectiveHeader = header.isNotEmpty
      ? header
      : [ParagraphNode(links: null,
           nodes: [TextNode(zulipLocalizations.spoilerDefaultHeaderText)])];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 15),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Web has the same color in light and dark mode.
          border: Border.all(color: const Color(0xff808080)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(padding: const EdgeInsetsDirectional.fromSTEB(10, 2, 8, 2),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _handleTap,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: weightVariableTextStyle(context, wght: 700),
                        child: BlockContentList(
                          nodes: effectiveHeader))),
                    RotationTransition(
                      turns: _animation.drive(Tween(begin: 0, end: 0.5)),
                      // Web has the same color in light and dark mode.
                      child: const Icon(color: Color(0xffd4d4d4), size: 25,
                        Icons.expand_more)),
                  ]))),
              FadeTransition(
                opacity: _animation,
                child: const SizedBox(height: 0, width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        // Web has the same color in light and dark mode.
                        bottom: BorderSide(width: 1, color: Color(0xff808080))))))),
              SizeTransition(
                sizeFactor: _animation,
                axis: Axis.vertical,
                axisAlignment: -1,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: BlockContentList(nodes: widget.node.content))),
            ]))));
  }
}

class MessageImageList extends StatelessWidget {
  const MessageImageList({super.key, required this.node});

  final ImageNodeList node;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: node.images.map((imageNode) => MessageImage(node: imageNode)).toList());
  }
}

class MessageImage extends StatelessWidget {
  const MessageImage({super.key, required this.node});

  final ImageNode node;

  @override
  Widget build(BuildContext context) {
    final message = InheritedMessage.of(context);

    // TODO image hover animation
    final srcUrl = node.srcUrl;
    final thumbnailUrl = node.thumbnailUrl;
    final store = PerAccountStoreWidget.of(context);
    final resolvedSrcUrl = store.tryResolveUrl(srcUrl);
    final resolvedThumbnailUrl = thumbnailUrl == null
      ? null : store.tryResolveUrl(thumbnailUrl);

    // TODO if src fails to parse, show an explicit "broken image"

    return MessageMediaContainer(
      onTap: resolvedSrcUrl == null ? null : () { // TODO(log)
        Navigator.of(context).push(getImageLightboxRoute(
          context: context,
          message: message,
          messageImageContext: context,
          src: resolvedSrcUrl,
          thumbnailUrl: resolvedThumbnailUrl,
          originalWidth: node.originalWidth,
          originalHeight: node.originalHeight));
      },
      child: node.loading
        ? const CupertinoActivityIndicator()
        : resolvedSrcUrl == null ? null : LightboxHero(
            messageImageContext: context,
            src: resolvedSrcUrl,
            child: RealmContentNetworkImage(
              resolvedThumbnailUrl ?? resolvedSrcUrl,
              filterQuality: FilterQuality.medium)));
  }
}

class MessageInlineVideo extends StatelessWidget {
  const MessageInlineVideo({super.key, required this.node});

  final InlineVideoNode node;

  @override
  Widget build(BuildContext context) {
    final message = InheritedMessage.of(context);
    final store = PerAccountStoreWidget.of(context);
    final resolvedSrc = store.tryResolveUrl(node.srcUrl);

    return MessageMediaContainer(
      onTap: resolvedSrc == null ? null : () { // TODO(log)
        Navigator.of(context).push(getVideoLightboxRoute(
          context: context,
          message: message,
          src: resolvedSrc));
      },
      child: Container(
        color: Colors.black, // Web has the same color in light and dark mode.
        alignment: Alignment.center,
        // To avoid potentially confusing UX, do not show play icon as
        // we also disable onTap above.
        child: resolvedSrc == null ? null : const Icon( // TODO(log)
          Icons.play_arrow_rounded,
          color: Colors.white, // Web has the same color in light and dark mode.
          size: 32)));
  }
}

class MessageEmbedVideo extends StatelessWidget {
  const MessageEmbedVideo({super.key, required this.node});

  final EmbedVideoNode node;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final previewImageSrcUrl = store.tryResolveUrl(node.previewImageSrcUrl);

    return MessageMediaContainer(
      onTap: () => _launchUrl(context, node.hrefUrl),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (previewImageSrcUrl != null) // TODO(log)
            RealmContentNetworkImage(
              previewImageSrcUrl,
              filterQuality: FilterQuality.medium),
          // Show the "play" icon even when previewImageSrcUrl didn't resolve;
          // the action uses hrefUrl, which might still work.
          const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white, // Web has the same color in light and dark mode.
            size: 32),
        ]));
  }
}

class MessageMediaContainer extends StatelessWidget {
  const MessageMediaContainer({
    super.key,
    required this.onTap,
    required this.child,
  });

  final void Function()? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: UnconstrainedBox(
        alignment: Alignment.centerLeft,
        child: Padding(
          // TODO clean up this padding by imitating web less precisely;
          //   in particular, avoid adding loose whitespace at end of message.
          padding: const EdgeInsets.only(right: 5, bottom: 5),
          child: ColoredBox(
            color: ContentTheme.of(context).colorMessageMediaContainerBackground,
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: SizedBox(
                height: 100,
                width: 150,
                child: child))))));
  }
}

class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.node});

  final CodeBlockNode node;

  @override
  Widget build(BuildContext context) {
    final styles = ContentTheme.of(context).codeBlockTextStyles;
    return _CodeBlockContainer(
      borderColor: Colors.transparent,
      child: Text.rich(TextSpan(
        style: styles.plain,
        children: node.spans
          .map((node) => TextSpan(style: styles.forSpan(node.type), text: node.text))
          .toList(growable: false))));
  }
}

class _CodeBlockContainer extends StatelessWidget {
  const _CodeBlockContainer({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ContentTheme.of(context).colorCodeBlockBackground,
        border: Border.all(
          width: 1,
          color: borderColor),
        borderRadius: BorderRadius.circular(4)),
      child: SingleChildScrollViewWithScrollbar(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 5, 7, 3),
          child: child)));
  }
}

class MathBlock extends StatelessWidget {
  const MathBlock({super.key, required this.node});

  final MathBlockNode node;

  @override
  Widget build(BuildContext context) {
    final contentTheme = ContentTheme.of(context);

    final nodes = node.nodes;
    if (nodes == null) {
      return _CodeBlockContainer(
        borderColor: contentTheme.colorMathBlockBorder,
        child: Text.rich(TextSpan(
          style: contentTheme.codeBlockTextStyles.plain,
          children: [TextSpan(text: node.texSource)])));
    }

    return Center(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollViewWithScrollbar(
          scrollDirection: Axis.horizontal,
          child: KatexWidget(
            textStyle: ContentTheme.of(context).textStylePlainParagraph,
            nodes: nodes))));
  }
}

class WebsitePreview extends StatelessWidget {
  const WebsitePreview({super.key, required this.node});

  final WebsitePreviewNode node;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final resolvedImageSrcUrl = store.tryResolveUrl(node.imageSrcUrl);
    final isSmallWidth = MediaQuery.sizeOf(context).width <= 576;

    // On Web on larger width viewports, the title and description container's
    // width is constrained using `max-width: calc(100% - 115px)`, we do not
    // follow the same here for potential benefits listed here:
    //   https://github.com/zulip/zulip-flutter/pull/1049#discussion_r1915740997
    final titleAndDescription = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (node.title != null)
          GestureDetector(
            onTap: () => _launchUrl(context, node.hrefUrl),
            child: Text(node.title!,
              style: TextStyle(
                fontSize: 1.2 * kBaseFontSize,
                // Web uses `line-height: normal` for title. MDN docs for it:
                //   https://developer.mozilla.org/en-US/docs/Web/CSS/line-height#normal
                // says actual value depends on user-agent, and default value
                // can be roughly 1.2 (unitless). So, use the same here.
                height: 1.2,
                color: ContentTheme.of(context).colorLink))),
        if (node.description != null)
          Container(
            padding: const EdgeInsets.only(top: 3),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(node.description!)),
      ]);

    final clippedTitleAndDescription = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: InsetShadowBox(
        bottom: 8,
        // TODO(#488) use different color for non-message contexts
        // TODO(#647) use different color for highlighted messages
        // TODO(#681) use different color for DM messages
        color: DesignVariables.of(context).bgMessageRegular,
        child: ClipRect(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 80),
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: AlignmentDirectional.topStart,
              fit: OverflowBoxFit.deferToChild,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: titleAndDescription))))));

    final image = resolvedImageSrcUrl == null ? null
      : GestureDetector(
          onTap: () => _launchUrl(context, node.hrefUrl),
          child: RealmContentNetworkImage(
            resolvedImageSrcUrl,
            fit: BoxFit.cover));

    final result = isSmallWidth
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 15,
          children: [
            if (image != null)
              SizedBox(height: 110, width: double.infinity, child: image),
            clippedTitleAndDescription,
          ])
      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (image != null)
            SizedBox.square(dimension: 80, child: image),
          Flexible(child: clippedTitleAndDescription),
        ]);

    return Padding(
      // TODO(?) Web has a bottom margin `--markdown-interelement-space-px`
      //   around the `message_embed` container, which is calculated here:
      //     https://github.com/zulip/zulip/blob/d28f7d86223bab4f11629637d4237381943f6fc1/web/src/information_density.ts#L80-L102
      //   But for now we use a static value of 6.72px instead which is the
      //   default in the web client, see discussion:
      //     https://github.com/zulip/zulip-flutter/pull/1049#discussion_r1915747908
      padding: const EdgeInsets.only(bottom: 6.72),
      child: Container(
        height: !isSmallWidth ? 90 : null,
        decoration: const BoxDecoration(
          border: BorderDirectional(start: BorderSide(
            // Web has the same color in light and dark mode.
            color: Color(0xffededed), width: 3))),
        padding: const EdgeInsets.all(5),
        child: result));
  }
}

//
// Inline layout.
//

Widget _buildBlockInlineContainer({
  required TextStyle style,
  required BlockInlineContainerNode node,
  TextAlign? textAlign,
}) {
  if (node.links == null) {
    return InlineContent(recognizer: null, linkRecognizers: null,
      style: style, nodes: node.nodes, textAlign: textAlign);
  }
  return _BlockInlineContainer(links: node.links!,
    style: style, nodes: node.nodes, textAlign: textAlign);
}

class _BlockInlineContainer extends StatefulWidget {
  const _BlockInlineContainer({
    required this.links,
    required this.style,
    required this.nodes,
    this.textAlign,
  });

  final List<LinkNode> links;
  final TextStyle style;
  final List<InlineContentNode> nodes;
  final TextAlign? textAlign;

  @override
  State<_BlockInlineContainer> createState() => _BlockInlineContainerState();
}

class _BlockInlineContainerState extends State<_BlockInlineContainer> {
  final Map<LinkNode, GestureRecognizer> _recognizers = {};

  void _prepareRecognizers() {
    _recognizers.addEntries(widget.links.map((node) => MapEntry(node,
      TapGestureRecognizer()..onTap = () => _launchUrl(context, node.url))));
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void initState() {
    super.initState();
    _prepareRecognizers();
  }

  @override
  void didUpdateWidget(covariant _BlockInlineContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.links, oldWidget.links)) {
      _disposeRecognizers();
      _prepareRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InlineContent(recognizer: null, linkRecognizers: _recognizers,
      style: widget.style, nodes: widget.nodes, textAlign: widget.textAlign);
  }
}

class InlineContent extends StatelessWidget {
  InlineContent({
    super.key,
    required this.recognizer,
    required this.linkRecognizers,
    required this.style,
    required this.nodes,
    this.textAlign,
  }) {
    assert(style.fontSize != null);
    assert(
      style.debugLabel!.contains('weightVariableTextStyle')
      // ([ContentTheme.textStylePlainParagraph] applies [weightVariableTextStyle])
      || style.debugLabel!.contains('ContentTheme.textStylePlainParagraph')
      || style.debugLabel!.contains('bolderWghtTextStyle')
    );
    _builder = _InlineContentBuilder(this);
  }

  final GestureRecognizer? recognizer;
  final Map<LinkNode, GestureRecognizer>? linkRecognizers;

  /// A [TextStyle] applied to this content and provided to descendants.
  ///
  /// Must set [TextStyle.fontSize]. Some descendant spans will consume it,
  /// e.g., to make their content slightly smaller than surrounding text.
  /// Similarly must set a font weight using [weightVariableTextStyle].
  final TextStyle style;

  /// A [TextAlign] applied to this content.
  final TextAlign? textAlign;

  final List<InlineContentNode> nodes;

  late final _InlineContentBuilder _builder;

  @override
  Widget build(BuildContext context) {
    return Text.rich(_builder.build(context), textAlign: textAlign);
  }
}

class _InlineContentBuilder {
  _InlineContentBuilder(this.widget) : _recognizer = widget.recognizer;

  final InlineContent widget;

  InlineSpan build(BuildContext context) {
    assert(_context == null);
    _context = context;
    assert(_recognizer == widget.recognizer);
    assert(_recognizerStack == null || _recognizerStack!.isEmpty);
    final result = _buildNodes(widget.nodes, style: widget.style);
    assert(identical(_context, context));
    _context = null;
    assert(_recognizer == widget.recognizer);
    assert(_recognizerStack == null || _recognizerStack!.isEmpty);
    return result;
  }

  BuildContext? _context;

  // Why do we have to track `recognizer` here, rather than apply it
  // once at the top of the affected span?  Because the events don't bubble
  // within a paragraph:
  //   https://github.com/flutter/flutter/issues/10623
  //   https://github.com/flutter/flutter/issues/10623#issuecomment-308030170
  GestureRecognizer? _recognizer;

  List<GestureRecognizer?>? _recognizerStack;

  void _pushRecognizer(GestureRecognizer? newRecognizer) {
    (_recognizerStack ??= []).add(_recognizer);
    _recognizer = newRecognizer;
  }

  void _popRecognizer() {
    _recognizer = _recognizerStack!.removeLast();
  }

  InlineSpan _buildNodes(List<InlineContentNode> nodes, {required TextStyle? style}) {
    return TextSpan(
      style: style,
      children: nodes.map(_buildNode).toList(growable: false));
  }

  InlineSpan _buildNode(InlineContentNode node) {
    switch (node) {
      case TextNode():
        return TextSpan(text: node.text, recognizer: _recognizer);

      case LineBreakInlineNode():
        // Each `<br/>` is followed by a newline, which browsers apparently ignore
        // and our parser doesn't.  So don't do anything here.
        return const TextSpan(text: "");

      case StrongNode():
        return _buildNodes(node.nodes,
          style: bolderWghtTextStyle(widget.style, by: 200));

      case DeletedNode():
        return _buildNodes(node.nodes,
          style: const TextStyle(decoration: TextDecoration.lineThrough));

      case EmphasisNode():
        return _buildNodes(node.nodes,
          style: const TextStyle(fontStyle: FontStyle.italic));

      case LinkNode():
        final recognizer = widget.linkRecognizers?[node];
        assert(recognizer != null);
        _pushRecognizer(recognizer);
        final result = _buildNodes(node.nodes,
          style: TextStyle(color: ContentTheme.of(_context!).colorLink));
        _popRecognizer();
        return result;

      case InlineCodeNode():
        return _buildInlineCode(node);

      case UserMentionNode():
        return WidgetSpan(alignment: PlaceholderAlignment.middle,
          child: UserMention(ambientTextStyle: widget.style, node: node));

      case UnicodeEmojiNode():
        return TextSpan(text: node.emojiUnicode, recognizer: _recognizer,
          style: widget.style
            .merge(ContentTheme.of(_context!).textStyleEmoji));

      case ImageEmojiNode():
        return WidgetSpan(alignment: PlaceholderAlignment.middle,
          child: MessageImageEmoji(node: node));

      case MathInlineNode():
        final nodes = node.nodes;
        return nodes == null
          ? TextSpan(
              style: widget.style
                .merge(ContentTheme.of(_context!).textStyleInlineMath)
                .apply(fontSizeFactor: kInlineCodeFontSizeFactor),
              children: [TextSpan(text: node.texSource)])
          : WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: KatexWidget(textStyle: widget.style, nodes: nodes));

      case GlobalTimeNode():
        return WidgetSpan(alignment: PlaceholderAlignment.middle,
          child: GlobalTime(node: node, ambientTextStyle: widget.style));

      case UnimplementedInlineContentNode():
        return _errorUnimplemented(node, context: _context!);
    }
  }

  InlineSpan _buildInlineCode(InlineCodeNode node) {
    // TODO `code` elements: border, padding -- seems hard
    //
    // Hard because this is an inline span, which we want to be able to break
    // between lines when wrapping paragraphs.  That means we can't just make it a
    // widget; it needs to be a [TextSpan].  And in that inline setting, Flutter
    // does not appear to have an equivalent for CSS's `border` or `padding`:
    //   https://api.flutter.dev/flutter/painting/TextStyle-class.html
    //
    // One attempt was to use [TextDecoration] for the top and bottom,
    // passing this to the [TextStyle] constructor:
    //   decoration: TextDecoration.combine([TextDecoration.overline, TextDecoration.underline]),
    // (Then we could handle the left and right borders with 1px-wide [WidgetSpan]s.)
    // The overline comes out OK, but sadly the underline is, well, where a normal
    // text underline should go: it cuts right through descenders.
    //
    // Another option would be to break the text up on whitespace ourselves, and
    // make a [WidgetSpan] for each word and space.
    //
    // Or we could find a different design for displaying inline code.
    // One such alternative is implemented below.

    // TODO `code`: find equivalent of web's `unicode-bidi: embed; direction: ltr`

    return _buildNodes(
      style: widget.style
        .merge(ContentTheme.of(_context!).textStyleInlineCode)
        .apply(fontSizeFactor: kInlineCodeFontSizeFactor),
      node.nodes,
    );

    // Another fun solution -- we can in fact have a border!  Like so:
    //   TextStyle(
    //     background: Paint()..color = Color(0xff000000)
    //                        ..style = PaintingStyle.stroke,
    //     // … fontSize, fontFamily, …
    // The trouble is that this border hugs the text tightly -- no padding.
    // That doesn't come out looking good.

    // Here's a more different solution: add delimiters.
    // return TextSpan(children: [
    //   // TO.DO(selection): exclude these brackets from text selection
    //   const TextSpan(text: _kInlineCodeLeftBracket),
    //   TextSpan(style: _kCodeStyle, children: _buildInlineList(element.nodes)),
    //   const TextSpan(text: _kInlineCodeRightBracket),
    // ]);
  }
}

const kInlineCodeFontSizeFactor = 0.825;

class UserMention extends StatelessWidget {
  const UserMention({
    super.key,
    required this.ambientTextStyle,
    required this.node,
  });

  final TextStyle ambientTextStyle;
  final UserMentionNode node;

  @override
  Widget build(BuildContext context) {
    final contentTheme = ContentTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        // TODO(#646) different for wildcard mentions
        color: contentTheme.colorDirectMentionBackground,
        borderRadius: const BorderRadius.all(Radius.circular(3))),
      padding: const EdgeInsets.symmetric(horizontal: 0.2 * kBaseFontSize),
      child: InlineContent(
        // If an @-mention is inside a link, let the @-mention override it.
        recognizer: null,  // TODO make @-mentions tappable, for info on user
        // One hopes an @-mention can't contain an embedded link.
        // (The parser on creating a UserMentionNode has a TODO to check that.)
        linkRecognizers: null,

        // TODO(#647) when self-user is non-silently mentioned, make bold, and:
        // TODO(#646) when self-user is non-silently mentioned,
        //   distinguish font color between direct and wildcard mentions
        style: ambientTextStyle,

        nodes: node.nodes));
  }

// This is a more literal translation of Zulip web's CSS.
// But it turns out CSS `box-shadow` has a quirk we rely on there:
// it doesn't apply under the element itself, even if the element's
// own background is transparent.  Flutter's BoxShadow does apply,
// which is after all more logical from the "shadow" metaphor.
//
// static const _kDecoration = ShapeDecoration(
//   gradient: LinearGradient(
//     colors: [Color.fromRGBO(0, 0, 0, 0.1), Color.fromRGBO(0, 0, 0, 0)],
//     begin: Alignment.topCenter,
//     end: Alignment.bottomCenter),
//   shadows: [
//     BoxShadow(
//       spreadRadius: 1,
//       blurStyle: BlurStyle.outer,
//       color: Color.fromRGBO(0xcc, 0xcc, 0xcc, 1)),
//   ],
//   shape: RoundedRectangleBorder(
//     borderRadius: BorderRadius.all(Radius.circular(3))));
}

class MessageImageEmoji extends StatelessWidget {
  const MessageImageEmoji({super.key, required this.node});

  final ImageEmojiNode node;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final resolvedSrc = store.tryResolveUrl(node.src);

    const size = 20.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        const SizedBox(width: size, height: kBaseFontSize),
        Positioned(
          // Web's css makes this seem like it should be -0.5, but that looks
          // too low.
          top: -1.5,
          child: resolvedSrc == null ? const SizedBox.shrink() // TODO(log)
            : RealmContentNetworkImage(
                resolvedSrc,
                filterQuality: FilterQuality.medium,
                width: size,
                height: size,
              )),
      ]);
  }
}

class GlobalTime extends StatelessWidget {
  const GlobalTime({
    super.key,
    required this.node,
    required this.ambientTextStyle,
  });

  final GlobalTimeNode node;
  final TextStyle ambientTextStyle;

  static final _format12 =
    intl.DateFormat('EEE, MMM d, y').addPattern('h:mm aa', ', ');
  static final _format24 =
    intl.DateFormat('EEE, MMM d, y').addPattern('Hm', ', ');
  static final _formatLocaleDefault =
    intl.DateFormat('EEE, MMM d, y').addPattern('jm', ', ');

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final twentyFourHourTimeMode = store.userSettings.twentyFourHourTime;
    // Design taken from css for `.rendered_markdown & time` in web,
    //   see zulip:web/styles/rendered_markdown.css .
    // TODO(i18n): localize; see plan with ffi in #45
    final format = switch (twentyFourHourTimeMode) {
      TwentyFourHourTimeMode.twelveHour => _format12,
      TwentyFourHourTimeMode.twentyFourHour => _format24,
      TwentyFourHourTimeMode.localeDefault => _formatLocaleDefault,
    };
    final text = format.format(node.datetime.toLocal());
    final contentTheme = ContentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: contentTheme.colorGlobalTimeBackground,
          border: Border.all(width: 1, color: contentTheme.colorGlobalTimeBorder),
          borderRadius: BorderRadius.circular(3)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.2 * kBaseFontSize),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                size: ambientTextStyle.fontSize!,
                // (When GlobalTime appears in a link, it should be blue
                // like the text.)
                color: DefaultTextStyle.of(context).style.color!,
                ZulipIcons.clock),
              // Ad-hoc spacing adjustment per feedback:
              //   https://chat.zulip.org/#narrow/stream/101-design/topic/clock.20icons/near/1729345
              const SizedBox(width: 1),
              Text(text, style: ambientTextStyle),
            ]))));
  }
}

class MessageTable extends StatelessWidget {
  const MessageTable({super.key, required this.node});

  final TableNode node;

  @override
  Widget build(BuildContext context) {
    final contentTheme = ContentTheme.of(context);
    return SingleChildScrollViewWithScrollbar(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Table(
          border: TableBorder.all(
            width: 1,
            style: BorderStyle.solid,
            color: contentTheme.colorTableCellBorder),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: List.unmodifiable(node.rows.map((row) => TableRow(
            decoration: row.isHeader
              ? BoxDecoration(color: contentTheme.colorTableHeaderBackground)
              : null,
            children: List.unmodifiable(row.cells.map((cell) =>
              MessageTableCell(node: cell, isHeader: row.isHeader)))))))));
  }
}

class MessageTableCell extends StatelessWidget {
  const MessageTableCell({super.key, required this.node, required this.isHeader});

  final TableCellNode node;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final textAlign = switch (node.textAlignment) {
      TableColumnTextAlignment.left => TextAlign.left,
      TableColumnTextAlignment.center => TextAlign.center,
      TableColumnTextAlignment.right => TextAlign.right,
      // The web client sets `text-align: left;` for the header cells,
      // overriding the default browser alignment (which is `center` for header
      // and `start` for body). By default, the [Table] widget uses `start` for
      // text alignment, a saner choice that supports RTL text. So, defer to that.
      // See discussion:
      //  https://github.com/zulip/zulip-flutter/pull/1031#discussion_r1831950371
      TableColumnTextAlignment.defaults => null,
    };
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        // Web has 4px padding and 1px border on all sides.
        // In web, the 1px border grows each cell by 0.5px in all directions.
        // Our border doesn't affect the layout, it's just painted on,
        // so we add 0.5px on all sides to match web.
        // Ref: https://github.com/flutter/flutter/issues/78691
        padding: const EdgeInsets.all(4 + 0.5),
        child: node.nodes.isEmpty
          ? const SizedBox.shrink()
          : _buildBlockInlineContainer(
              node: node,
              textAlign: textAlign,
              style: !isHeader
                ? DefaultTextStyle.of(context).style
                : DefaultTextStyle.of(context).style
                    .merge(weightVariableTextStyle(context, wght: 700))),
      ));
  }
}

void _launchUrl(BuildContext context, String urlString) async {
  final store = PerAccountStoreWidget.of(context);
  final url = store.tryResolveUrl(urlString);
  if (url == null) { // TODO(log)
    final zulipLocalizations = ZulipLocalizations.of(context);
    showErrorDialog(context: context,
      title: zulipLocalizations.errorCouldNotOpenLinkTitle,
      message: zulipLocalizations.errorCouldNotOpenLink(urlString));
    return;
  }

  final internalLink = parseInternalLink(url, store);
  assert(internalLink == null || internalLink.realmUrl == store.realmUrl);
  switch (internalLink) {
    case NarrowLink():
      unawaited(Navigator.push(context,
        MessageListPage.buildRoute(context: context,
          narrow: internalLink.narrow,
          initAnchorMessageId: internalLink.nearMessageId)));

    case null:
      await PlatformActions.launchUrl(context, url);
  }
}

/// Like [Image.network], but includes [authHeader] if [src] is on-realm.
///
/// Use this to present image content in the ambient realm: avatars, images in
/// messages, etc. Must have a [PerAccountStoreWidget] ancestor.
///
/// If [src] is an on-realm URL (it has the same origin as the ambient
/// [Auth.realmUrl]), then an HTTP request to fetch the image will include the
/// user's [authHeader].
///
/// If [src] is off-realm (e.g., a Gravatar URL), no auth header will be sent.
///
/// The image will be cached according to the cache behavior of [Image.network],
/// which may mean the cache is shared between realms.
class RealmContentNetworkImage extends StatelessWidget {
  const RealmContentNetworkImage(
    this.src, {
    super.key,
    this.scale = 1.0,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    // `headers` skipped
    this.cacheWidth,
    this.cacheHeight,
  });

  final Uri src;

  final double scale;
  final ImageFrameBuilder? frameBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final double? width;
  final double? height;
  final Color? color;
  final Animation<double>? opacity;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final bool isAntiAlias;
  // `headers` skipped
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final account = PerAccountStoreWidget.of(context).account;

    return Image.network(
      src.toString(),

      scale: scale,
      frameBuilder: frameBuilder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      filterQuality: filterQuality,
      isAntiAlias: isAntiAlias,
      headers: {
        // Only send the auth header to the server `auth` belongs to.
        if (src.origin == account.realmUrl.origin) ...authHeader(
          email: account.email, apiKey: account.apiKey,
        ),
        ...userAgentHeader(),
      },
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}

//
// Small helpers.
//

InlineSpan _errorUnimplemented(UnimplementedNode node, {required BuildContext context}) {
  final contentTheme = ContentTheme.of(context);
  final errorStyle = contentTheme.textStyleError;
  final errorCodeStyle = contentTheme.textStyleErrorCode;
  // For now this shows error-styled HTML code even in release mode,
  // because release mode isn't yet about general users but developer demos,
  // and we want to keep the demos honest.
  // TODO(#194) think through UX for general release
  // TODO(#1285) translate this
  final htmlNode = node.htmlNode;
  if (htmlNode is dom.Element) {
    return TextSpan(children: [
      TextSpan(text: "(unimplemented:", style: errorStyle),
      TextSpan(text: htmlNode.outerHtml, style: errorCodeStyle),
      TextSpan(text: ")", style: errorStyle),
    ]);
  } else if (htmlNode is dom.Text) {
    return TextSpan(children: [
      TextSpan(text: "(unimplemented: text «", style: errorStyle),
      TextSpan(text: htmlNode.text, style: errorCodeStyle),
      TextSpan(text: "»)", style: errorStyle),
    ]);
  } else {
    return TextSpan(
      text: "(unimplemented: DOM node type ${htmlNode.nodeType})",
      style: errorStyle);
  }
}
