import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  final controller = WebViewController();
  Completer<void>? _completer;

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
  void initState() {
    super.initState();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => finishRefresh(),
          onWebResourceError: (error) => finishRefresh(),
        ),
      )
      ..loadRequest(Uri.parse('https://garasiasatu.com/mobile'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(backgroundColor: Colors.white24),
      ),
      body: WebviewRefresher(controller: controller, onRefresh: onRefresh),
    );
  }
}
