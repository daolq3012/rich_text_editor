import 'package:flutter/material.dart';

import 'package:rich_text_html_editor/rich_editor.dart';

import 'rich_editor_toolbar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flutter Demo Rich Editor'),
      );
}

// create MyHomePage stateless widget class with title property
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // final property title
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final GlobalKey<RichEditorState> _richEditorKey;
  late final GlobalKey<RichEditorToolbarState> _richToolbarEditorKey;

  @override
  void initState() {
    super.initState();
    _richEditorKey = GlobalKey<RichEditorState>();
    _richToolbarEditorKey = GlobalKey<RichEditorToolbarState>();
  }

  // build method
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            children: [
              RichEditorToolbar(
                key: _richToolbarEditorKey,
                onTap: (EditorStyleType style) {
                  // ignore: missing_enum_constant_in_switch
                  switch (style) {
                    case EditorStyleType.BOLD:
                      _richEditorKey.currentState?.setBold();
                      break;
                    case EditorStyleType.ITALIC:
                      _richEditorKey.currentState?.setItalic();
                      break;
                    case EditorStyleType.STRIKETHROUGH:
                      _richEditorKey.currentState?.setStrikeThrough();
                      break;
                    case EditorStyleType.UNDERLINE:
                      _richEditorKey.currentState?.setUnderline();
                      break;
                    case EditorStyleType.UNORDERED_LIST:
                      _richEditorKey.currentState?.setBullets();
                      break;
                  }
                },
              ),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(246, 246, 246, 1),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: SizedBox(
                  height: 100,
                  child: RichEditor(
                    key: _richEditorKey,
                    placeholder: 'Sample placeholder',
                    onStyleTextFocused: (editorStyles) {
                      _richToolbarEditorKey.currentState
                          ?.updateStyle(editorStyles);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
