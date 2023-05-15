import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rich_text_editor/rich_editor.dart';

import 'assets_image.dart';

class RichEditorToolbar extends StatefulWidget {
  static const double _kDefaultSize = 36;
  final double size;
  final Function(EditorStyleType editorType) onTap;

  const RichEditorToolbar({
    Key? key,
    this.size = _kDefaultSize,
    required this.onTap,
  }) : super(key: key);

  @override
  RichEditorToolbarState createState() => RichEditorToolbarState();
}

class RichEditorToolbarState extends State<RichEditorToolbar> {
  late final ValueNotifier<bool> _boldNotifier;
  late final ValueNotifier<bool> _italicNotifier;
  late final ValueNotifier<bool> _underlineNotifier;
  late final ValueNotifier<bool> _strikeThroughNotifier;
  late final ValueNotifier<bool> _unOrderedListNotifier;
  late final ValueNotifier<bool> _orderedListNotifier;

  @override
  void initState() {
    super.initState();
    _boldNotifier = ValueNotifier(false);
    _italicNotifier = ValueNotifier(false);
    _underlineNotifier = ValueNotifier(false);
    _strikeThroughNotifier = ValueNotifier(false);
    _unOrderedListNotifier = ValueNotifier(false);
    _orderedListNotifier = ValueNotifier(false);
  }

  @override
  void dispose() {
    _boldNotifier.dispose();
    _italicNotifier.dispose();
    _underlineNotifier.dispose();
    _strikeThroughNotifier.dispose();
    _unOrderedListNotifier.dispose();
    _orderedListNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Row(
          children: [
            _wrapToggleButton(_boldNotifier, EditorStyleType.BOLD),
            _wrapToggleButton(_italicNotifier, EditorStyleType.ITALIC),
            _wrapToggleButton(_underlineNotifier, EditorStyleType.UNDERLINE),
            _wrapToggleButton(
                _strikeThroughNotifier, EditorStyleType.STRIKETHROUGH),
            _wrapToggleButton(
                _unOrderedListNotifier, EditorStyleType.UNORDERED_LIST),
            _wrapToggleButton(
                _orderedListNotifier, EditorStyleType.ORDERED_LIST),
          ],
        ),
      );

  void updateStyle(List<EditorStyleType> types) {
    _boldNotifier.value = types.contains(EditorStyleType.BOLD);
    _italicNotifier.value = types.contains(EditorStyleType.ITALIC);
    _underlineNotifier.value = types.contains(EditorStyleType.UNDERLINE);
    _strikeThroughNotifier.value =
        types.contains(EditorStyleType.STRIKETHROUGH);
    _unOrderedListNotifier.value =
        types.contains(EditorStyleType.UNORDERED_LIST);
    _orderedListNotifier.value = types.contains(EditorStyleType.ORDERED_LIST);
  }

  Widget _wrapToggleButton(
          ValueNotifier<bool> notifier, EditorStyleType type) =>
      GestureDetector(
        onTap: () {
          _toggle(type);
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          padding: const EdgeInsets.all(4),
          child: ValueListenableBuilder<bool>(
            valueListenable: notifier,
            builder: (_, isActive, __) => Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                // TODO refactor later
                color: isActive
                    ? const Color.fromRGBO(84, 95, 114, 0.1)
                    : Colors.white,
              ),
              child: _icon(type),
            ),
          ),
        ),
      );

  Widget _icon(EditorStyleType type) {
    String asset = '';
    switch (type) {
      case EditorStyleType.BOLD:
        asset = AssetsImage.bold;
        break;
      case EditorStyleType.ITALIC:
        asset = AssetsImage.italic;
        break;
      case EditorStyleType.UNDERLINE:
        asset = AssetsImage.underline;
        break;
      case EditorStyleType.STRIKETHROUGH:
        asset = AssetsImage.strikeThrough;
        break;
      case EditorStyleType.UNORDERED_LIST:
        asset = AssetsImage.bulletList;
        break;
      case EditorStyleType.ORDERED_LIST:
        asset = AssetsImage.numberList;
        break;
      default:
        break;
    }
    return asset.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(
            child: SvgPicture.asset(asset),
            width: widget.size / 2,
            height: widget.size / 2,
          );
  }

  void _toggle(EditorStyleType type) {
    switch (type) {
      case EditorStyleType.BOLD:
        _boldNotifier.value = !_boldNotifier.value;
        widget.onTap(EditorStyleType.BOLD);
        break;
      case EditorStyleType.ITALIC:
        _italicNotifier.value = !_italicNotifier.value;
        widget.onTap(EditorStyleType.ITALIC);
        break;
      case EditorStyleType.UNDERLINE:
        _underlineNotifier.value = !_underlineNotifier.value;
        widget.onTap(EditorStyleType.UNDERLINE);
        break;
      case EditorStyleType.STRIKETHROUGH:
        _strikeThroughNotifier.value = !_strikeThroughNotifier.value;
        widget.onTap(EditorStyleType.STRIKETHROUGH);
        break;
      case EditorStyleType.UNORDERED_LIST:
        _unOrderedListNotifier.value = !_unOrderedListNotifier.value;
        widget.onTap(EditorStyleType.UNORDERED_LIST);
        break;
      case EditorStyleType.ORDERED_LIST:
        _orderedListNotifier.value = !_orderedListNotifier.value;
        widget.onTap(EditorStyleType.ORDERED_LIST);
        break;
      default:
        break;
    }
  }
}
