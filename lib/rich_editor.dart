import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum EditorStyleType {
  BOLD,
  ITALIC,
  SUBSCRIPT,
  SUPERSCRIPT,
  STRIKETHROUGH,
  UNDERLINE,
  H1,
  H2,
  H3,
  H4,
  H5,
  H6,
  ORDERED_LIST,
  UNORDERED_LIST,
  JUSTIFY_CENTER,
  JUSTIFY_FULL,
  JUSTIFY_LEFT,
  JUSTIFY_RIGHT
}

extension EditorStyleTypeExtension on EditorStyleType {
  String get value {
    switch (this) {
      case EditorStyleType.BOLD:
        return 'BOLD';
      case EditorStyleType.ITALIC:
        return 'ITALIC';
      case EditorStyleType.SUBSCRIPT:
        return 'SUBSCRIPT';
      case EditorStyleType.SUPERSCRIPT:
        return 'SUPERSCRIPT';
      case EditorStyleType.STRIKETHROUGH:
        return 'STRIKETHROUGH';
      case EditorStyleType.UNDERLINE:
        return 'UNDERLINE';
      case EditorStyleType.H1:
        return 'H1';
      case EditorStyleType.H2:
        return 'H2';
      case EditorStyleType.H3:
        return 'H3';
      case EditorStyleType.H4:
        return 'H4';
      case EditorStyleType.H5:
        return 'H5';
      case EditorStyleType.H6:
        return 'H6';
      case EditorStyleType.ORDERED_LIST:
        return 'ORDEREDLIST';
      case EditorStyleType.UNORDERED_LIST:
        return 'UNORDEREDLIST';
      case EditorStyleType.JUSTIFY_CENTER:
        return 'JUSTIFYCENTER';
      case EditorStyleType.JUSTIFY_FULL:
        return 'JUSTIFYFULL';
      case EditorStyleType.JUSTIFY_LEFT:
        return 'JUSTIFYLEFT';
      case EditorStyleType.JUSTIFY_RIGHT:
        return 'JUSTIFYRIGHT';
      default:
        return '';
    }
  }

  static EditorStyleType? fromValue(String value) => EditorStyleType.values
      .firstWhereOrNull((element) => element.value == value);
}

class RichEditor extends StatefulWidget {
  final Function(String content)? onChanged;
  final Function(int)? onHeightChanged;
  final Function(bool)? onFocusChanged;
  final Function(List<EditorStyleType> editorStyles)? onStyleTextFocused;
  final bool isReadOnly;
  final String? placeholder;
  final String? initialValue;
  final Color loadingColor;
  final String fontColorHex;
  final bool isShowLoadingIndicator;
  final double loadingIndicatorSize;
  final bool useHybridComposition;

  const RichEditor({
    Key? key,
    this.onChanged,
    this.onHeightChanged,
    this.onFocusChanged,
    this.onStyleTextFocused,
    this.isReadOnly = false,
    this.placeholder,
    this.initialValue,
    this.loadingColor = Colors.white,
    this.fontColorHex = '#22313F',
    this.isShowLoadingIndicator = true,
    this.loadingIndicatorSize = 30,
    this.useHybridComposition = true,
  }) : super(key: key);

  @override
  RichEditorState createState() => RichEditorState();
}

class RichEditorState extends State<RichEditor> {
  static const String _kInitialFilePath =
      'packages/rich_text_html_editor/assets/editor/editor.html';
  static const String _kCallbackSchema = 're-callback://';
  static const String _kStateSchema = 're-state://';
  late final ValueNotifier<bool> _loadingNotifier;
  late final StreamController<bool> _isReadyStream;
  String _content = '';

  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _loadingNotifier = ValueNotifier(widget.isReadOnly);
    _isReadyStream = StreamController();
    _isReadyStream.stream.listen((bool isReady) {
      if (!isReady) {
        return;
      }
      widget.isReadOnly ? disableInput() : enableInput();
      setFontColor(widget.fontColorHex);
      setPlaceholder(widget.placeholder ?? '');
      final initialContent = (widget.initialValue ?? '')
          .replaceAll('<p>', '<div>')
          .replaceAll('</p>', '</div>');
      content = initialContent;
      _isReadyStream.close();
    });
  }

  @override
  void dispose() {
    _loadingNotifier.dispose();
    _isReadyStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.isReadOnly
      ? IgnorePointer(
          child: _buildBody(),
        )
      : _buildBody();

  Widget _buildBody() => ValueListenableBuilder<bool>(
        valueListenable: _loadingNotifier,
        builder: (_, isLoading, __) => Stack(
          children: [
            _buildWebView(),
            if (isLoading && widget.isReadOnly) _buildLoading(),
          ],
        ),
      );

  Widget _buildLoading() => Container(
        child: widget.isShowLoadingIndicator
            ? SizedBox(
                child: const CircularProgressIndicator(strokeWidth: 2),
                width: widget.loadingIndicatorSize,
                height: widget.loadingIndicatorSize,
              )
            : const SizedBox.shrink(),
        color: widget.loadingColor,
        alignment: Alignment.center,
      );

  Widget _buildWebView() => InAppWebView(
        initialFile: _kInitialFilePath,
        initialOptions: _initialOptions,
        onWebViewCreated: (controller) async {
          _controller = controller;
        },
        onWindowFocus: (_) {
          FocusScope.of(context).requestFocus();
          widget.onFocusChanged?.call(true);
        },
        onWindowBlur: (_) {
          widget.onFocusChanged?.call(false);
        },
        onLoadStop: (_, __) {
          if (!_isReadyStream.isClosed) {
            _isReadyStream.add(true);
          }
        },
        gestureRecognizers: {
          Factory(() => VerticalDragGestureRecognizer()..onUpdate = (_) {}),
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          String decode =
              Uri.decodeFull(navigationAction.request.url?.toString() ?? '');
          if (decode.startsWith(_kStateSchema)) {
            _handleState(decode);
            return NavigationActionPolicy.CANCEL;
          } else if (decode.startsWith(_kCallbackSchema)) {
            _handleCallback(decode);
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
      );

  String get originContent => _content;

  String get content {
    String result = _content
        .replaceAll('<strike>', '<s>')
        .replaceAll('</strike>', '</s>')
        .replaceAll('<div>', '<p>')
        .replaceAll('</div>', '</p>');
    return result.trim();
  }

  set content(String value) {
    final content = value;
    _controller?.evaluateJavascript(
        source: "javascript:RE.setHtml('$content');");
    _content = content;
    _updateHeight();
  }

  void setFontColor(String hexCode) {
    _controller?.evaluateJavascript(
        source: "javascript:RE.setBaseTextColor('$hexCode');");
  }

  void setFontSize(int px) {
    _controller?.evaluateJavascript(
        source: "javascript:RE.setBaseFontSize('${px}px');");
  }

  void setEditorWidth(int px) {
    _controller?.evaluateJavascript(
        source: "javascript:RE.setWidth('${px}px');");
  }

  void setEditorHeight(int? px) {
    if (px == null) {
      return;
    }
    _controller?.evaluateJavascript(
        source: "javascript:RE.setHeight('${px}px');");
  }

  void setPlaceholder(String placeholder) {
    _controller?.evaluateJavascript(
        source: "javascript:RE.setPlaceholder('$placeholder');");
  }

  void enableInput() {
    _controller?.evaluateJavascript(
        source: "javascript:RE.setInputEnabled('true');");
  }

  void disableInput() {
    _controller?.evaluateJavascript(
        source: "javascript:RE.setInputEnabled('false');");
  }

  void undo() {
    _controller?.evaluateJavascript(source: 'javascript:RE.undo();');
  }

  void redo() {
    _controller?.evaluateJavascript(source: 'javascript:RE.redo();');
  }

  void setBold() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setBold();');
  }

  void setItalic() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setItalic();');
  }

  void setSubscript() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setSubscript();');
  }

  void setSuperscript() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setSuperscript();');
  }

  void setStrikeThrough() {
    _controller?.evaluateJavascript(
        source: 'javascript:RE.setStrikeThrough();');
  }

  void setUnderline() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setUnderline();');
  }

  void setTextColor(String hexCode) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.setTextColor('$hexCode');");
  }

  void setTextBackgroundColor(String hexCode) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.setTextBackgroundColor('$hexCode');");
  }

  void removeFormat() {
    _controller?.evaluateJavascript(source: 'javascript:RE.removeFormat();');
  }

  void setHeading(int heading) {
    _controller?.evaluateJavascript(
        source: "javascript:RE.setHeading('$heading');");
  }

  void setIndent() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setIndent();');
  }

  void setOutdent() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setOutdent();');
  }

  void setAlignLeft() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setAlignLeft();');
  }

  void setAlignCenter() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setAlignCenter();');
  }

  void setAlignRight() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setAlignRight();');
  }

  void setBlockquote() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setBlockquote();');
  }

  void setBullets() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setBullets();');
  }

  void setNumbers() {
    _controller?.evaluateJavascript(source: 'javascript:RE.setNumbers();');
  }

  void focusEditor() {
    _controller?.evaluateJavascript(source: 'javascript:RE.focus();');
  }

  void insertImage(String url, String alt) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.insertImage('$url', '$alt');");
  }

  void insertImageW(String url, String alt, int width) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.insertImageW('$url', '$alt','$width');");
  }

  void insertImageWH(String url, String alt, int width, int height) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source:
            "javascript:RE.insertImageWH('$url', '$alt','$width', '$height');");
  }

  void insertVideo(String url) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.insertVideo('$url');");
  }

  void insertVideoW(String url, int width) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.insertVideoW('$url', '$width');");
  }

  void insertVideoWH(String url, int width, int height) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.insertVideoWH('$url', '$width', '$height');");
  }

  void insertAudio(String url) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.insertAudio('$url');");
  }

  void insertYoutubeVideo(String url) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.insertYoutubeVideo('$url');");
  }

  void insertYoutubeVideoW(String url, int width) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.insertYoutubeVideoW('$url', '$width');");
  }

  void insertYoutubeVideoWH(String url, int width, int height) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source:
            "javascript:RE.insertYoutubeVideoWH('$url', '$width', '$height');");
  }

  void insertLink(String href, String title) {
    _controller?.evaluateJavascript(source: 'javascript:RE.prepareInsert();');
    _controller?.evaluateJavascript(
        source: "javascript:RE.insertLink('$href', '$title');");
  }

  void focusCursor() {
    _controller?.evaluateJavascript(source: 'javascript:RE.focusCursor();');
  }

  void clearFocus() {
    _controller?.evaluateJavascript(source: 'javascript:RE.blurFocus();');
  }

  InAppWebViewGroupOptions get _initialOptions => InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          javaScriptEnabled: true,
          useShouldOverrideUrlLoading: true,
          horizontalScrollBarEnabled: false,
          verticalScrollBarEnabled: false,
          transparentBackground: true,
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: widget.useHybridComposition,
        ),
      );

  void _handleCallback(String scheme) {
    _content = scheme.replaceFirst(_kCallbackSchema, '');
    widget.onChanged?.call(content);
    _updateHeight();
    _controller?.evaluateJavascript(
        source: 'javascript:RE.enabledEditingItems();');
  }

  void _handleState(String scheme) {
    String state = scheme.replaceFirst(_kStateSchema, '').toUpperCase();
    final typesString = state.split(',');
    final types = typesString
        .map(EditorStyleTypeExtension.fromValue)
        .whereType<EditorStyleType>()
        .toList();
    widget.onStyleTextFocused?.call(types);
  }

  Future<void> _updateHeight() async {
    if (_controller == null) {
      return;
    }
    final value = await _controller?.evaluateJavascript(
        source: "javascript:document.getElementById('editor').clientHeight;");
    if (value is num) {
      if (widget.isReadOnly) {
        _loadingNotifier.value = true;
      }
      widget.onHeightChanged?.call(value.toInt());
      if (!widget.isReadOnly) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 600), () {
        _loadingNotifier.value = false;
      });
    }
  }
}
