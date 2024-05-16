import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:gyver_hub/core/env.dart';
import 'package:gyver_hub/core/js.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:web_view_ble/web_view_ble.dart';

class HubView extends StatefulWidget {
  const HubView({super.key});

  @override
  State<HubView> createState() => _HubViewState();
}

class _HubViewState extends State<HubView> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  final FlutterReactiveBle _flutterReactiveBle = FlutterReactiveBle();
  final List<DiscoveredDevice> _discoveredDevices = [];

  late TargetPlatform? platform;

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
  }

  DateTime? currentBackPressTime;

  bool initJs = false;

  @override
  Widget build(BuildContext context) {
    final topOffset = MediaQuery.of(context).padding.top;
    final bottomOffset = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvoked: (_) async {
        final status =
            await webViewController?.evaluateJavascript(source: JS.canGoBack);

        if (status != 'none') {
          await webViewController?.goBack();
          return;
        }

        final now = DateTime.now();
        if (currentBackPressTime == null ||
            now.difference(currentBackPressTime!) >
                const Duration(seconds: 2)) {
          currentBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Click again to exit'),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        extendBody: false,
        extendBodyBehindAppBar: false,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                top: false,
                bottom: false,
                child: InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(
                    url: Env.localServerUri,
                  ),
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      controller.evaluateJavascript(source: JS.cfgExport);
                      controller.evaluateJavascript(source: JS.cfgImport);
                      controller.evaluateJavascript(
                        source: JS.cfgDeviceType(Platform.operatingSystem),
                      );
                      controller.evaluateJavascript(
                        source: JS.setOffset(topOffset, bottomOffset),
                      );
                    }
                  },
                  initialSettings: InAppWebViewSettings(
                    supportZoom: false,
                    javaScriptEnabled: true,
                    allowFileAccess: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    alwaysBounceHorizontal: false,
                    horizontalScrollBarEnabled: false,
                    allowContentAccess: true,
                    algorithmicDarkeningAllowed: false,
                    forceDark: ForceDark.OFF,
                  ),
                  onReceivedServerTrustAuthRequest:
                      (controller, challenge) async {
                    print(challenge.protectionSpace);
                    return ServerTrustAuthResponse(
                      action: ServerTrustAuthResponseAction.PROCEED,
                    );
                  },
                  onConsoleMessage: (c, u) {
                    final msg = u.message;
                    try {
                      if (msg.startsWith('{') && msg.endsWith('}')) {
                        final res = jsonDecode(msg);
                        _downloadFile(res['name'], res['data']);
                      }
                    } catch (_) {}
                  },
                  onLoadStop: (controller, url) async {
                    // WebViewBle.init(controller: controller, context: context);
                    if (!initJs) {
                      initJs = true;
                      await controller.evaluateJavascript(
                        source: JS.cfgDownload,
                      );
                    }
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    final uri = navigationAction.request.url!;

                    if (uri.rawValue.contains('base64,')) {
                      return NavigationActionPolicy.CANCEL;
                    }

                    if (uri.host != Env.localServerUri.host) {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                  onWebViewCreated: (controller) async {
                    webViewController = controller;

                    webViewController?.addJavaScriptHandler(
                      handlerName: 'getDevice',
                      callback: (args) async {
                        await _requestPermissions();
                        return _connectToDevice(
                          _discoveredDevices as DiscoveredDevice,
                        );
                      },
                    );

                    webViewController?.addJavaScriptHandler(
                      handlerName: 'getClipboardText',
                      callback: (args) async {
                        final clipboardText = await _getFromClipboard();
                        return clipboardText;
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _downloadFile(String filename, String data) async {
    await _prepareSaveDir();
    final dir = await _findLocalPath();
    final x = data.split('base64,');
    final bytes = Base64Decoder().convert(x[1]);
    final filePath = '$dir/$filename'.replaceAll('//', '/');
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
    return file;
  }

  Future _prepareSaveDir() async {
    final localPath = await _findLocalPath();
    final savedDir = Directory(localPath);
    final hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  Future _findLocalPath() async {
    final directory = await getDownloadsDirectory();
    return '${directory!.path}${Platform.pathSeparator}GyverHub';
  }

  Future<String> _getFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    return clipboardData?.text ?? '';
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.location,
    ].request();

    // Check if permissions are granted
    if (statuses[Permission.location] == PermissionStatus.granted) {
      // Continue with Bluetooth operations
      _startScanning();
    } else {
      // Handle the case where permissions are not granted
      print('Location permission not granted');
    }
  }

  void _startScanning() {
    _flutterReactiveBle.scanForDevices(withServices: []).listen(
      (scanResult) {
        // Update the list of discovered devices
        setState(() {
          _discoveredDevices.add(scanResult);
        });
      },
      onError: (error) {
        // Handle scanning errors
        print('Scanning error: $error');
      },
    );
  }

  void _connectToDevice(DiscoveredDevice device) {
    // Add your logic to connect to the selected device
    print('Connecting to device: $device');
  }
}
