import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebScannerApp(),
    );
  }
}

class WebScannerApp extends StatefulWidget {
  @override
  _WebScannerAppState createState() => _WebScannerAppState();
}

class _WebScannerAppState extends State<WebScannerApp> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (url.endsWith(".pdf")) {
              _controller.runJavaScript("window.print();"); // Intenta imprimir automáticamente
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.endsWith(".pdf")) {
              _openPDF(request.url);
              return NavigationDecision.prevent; // Evita que el WebView cargue el PDF
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse("https://www.sicacyd.com/cafeteria/")); // Cambia la URL si es necesario
  }

  void _injectBarcodeValue(String barcode) {
    _controller.runJavaScript(
        "document.activeElement.value = '$barcode'; document.activeElement.dispatchEvent(new Event('input'));");
  }

  Future<void> _scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancelar", true, ScanMode.DEFAULT);
      if (barcodeScanRes != "-1") {
        _injectBarcodeValue(barcodeScanRes);
      }
    } catch (e) {
      barcodeScanRes = "Error al escanear código de barras.";
    }
  }

  void _openPDF(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        await _downloadAndOpenPDF(url);
      }
    } catch (e) {
      print("Error al abrir el PDF: $e");
    }
  }

  Future<void> _downloadAndOpenPDF(String url) async {
    try {
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/archivo.pdf");

      // 🔹 Si el archivo existe, elimínalo antes de descargar uno nuevo
      if (await file.exists()) {
        await file.delete();
      }

      // 📥 Descargar el nuevo archivo
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        OpenFile.open(file.path);
      }
    } catch (e) {
      print("Error al descargar el PDF: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 8,
              child: WebViewWidget(controller: _controller),
            ),
            ElevatedButton(
              onPressed: _scanBarcode,
              child: Text("Escanear Código de Barras"),
            ),
          ],
        ),
      ),
    );
  }
}
