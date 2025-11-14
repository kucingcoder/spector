import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
// Import baru
import 'package:image_picker/image_picker.dart';
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
  // Buat instance ImagePicker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    controller =
        WebViewController(onPermissionRequest: (request) => request.grant())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setUserAgent(
            "Garasi Asatu Spector ${Platform.isAndroid ? 'Android' : 'iOS'} Webview",
          )
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

  /// Menampilkan bottom sheet untuk memilih sumber gambar (Kamera vs Galeri)
  Future<ImageSource?> _showImageSourceSheet(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  /// MODIFIKASI UTAMA DI SINI
  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    // Periksa apakah web meminta file gambar
    final bool isImage = params.acceptTypes.any(
      (type) => type.startsWith('image/'),
    );

    if (isImage) {
      // Jika ya, tampilkan pilihan Kamera/Galeri
      ImageSource? source;
      if (mounted) {
        source = await _showImageSourceSheet(context);
      }

      if (source == null) return []; // User membatalkan pilihan

      final XFile? file = await _picker.pickImage(source: source);

      if (file == null) return []; // User membatalkan ambil gambar

      final fileUri = Uri.file(file.path).toString();
      debugPrint('Picked file URI: $fileUri');
      return [fileUri];
    } else {
      // Jika bukan gambar (misal PDF, dll), gunakan FilePicker biasa
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          // Hormati jika web meminta multiple files
          allowMultiple: params.mode == FileSelectorMode.openMultiple,
          withData: false,
        );

        if (result == null || result.files.isEmpty) return [];

        final files = result.paths
            .where((path) => path != null)
            .map((path) => Uri.file(path!).toString());

        debugPrint('Picked files URI: ${files.toList()}');
        return files.toList();
      } catch (e) {
        debugPrint('File picker error: $e');
        return [];
      }
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
    return WillPopScope(
      onWillPop: () async {
        if (await controller.canGoBack()) {
          controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
            color: Colors.white,
            child: WebviewRefresher(
              controller: controller,
              onRefresh: onRefresh,
            ),
          ),
        ),
      ),
    );
  }
}
