import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_refresher/webview_refresher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garasi Asatu Spector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const MyHomePage(title: 'Garasi Asatu Spector'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WebViewController controller;
  Completer<void>? _completer;

  @override
  void initState() {
    super.initState();

    controller =
        WebViewController(onPermissionRequest: (request) => request.grant())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) => finishRefresh(),
              onWebResourceError: (_) => finishRefresh(),
            ),
          )
          ..loadRequest(Uri.parse('https://garasiasatu.com/mobile'));

    if (Platform.isAndroid) {
      final AndroidWebViewController androidController =
          controller.platform as AndroidWebViewController;
      androidController.setOnShowFileSelector(_androidFilePicker);
    }
  }

  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return [];

      final filePath = result.files.single.path;
      if (filePath == null) return [];

      final fileUri = Uri.file(filePath).toString();
      debugPrint('Picked file URI: $fileUri');

      return [fileUri];
    } catch (e) {
      debugPrint('File picker error: $e');
      return [];
    }
  }

  Future<void> onRefresh() {
    _completer = Completer<void>();
    controller.reload();
    return _completer!.future;
  }

  void finishRefresh() {
    if (!(_completer?.isCompleted ?? true)) {
      _completer?.complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: WebviewRefresher(controller: controller, onRefresh: onRefresh),
        ),
      ),
    );
  }
}
