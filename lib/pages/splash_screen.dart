import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gyver_hub/env.dart';
import 'package:mini_server/mini_server_package.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../core/helpers.dart';

Future initPermission() async {
  await GetStorage.init();
  await Permission.storage.request();
  await Permission.location.request();

  // await Permission.bluetooth.request();
  // await Permission.bluetoothScan.request();
  // await Permission.bluetoothAdvertise.request();
  // await Permission.bluetoothConnect.request();

  // await askBlePermission();
}
//deprecated
askBlePermission() async {
  var blePermission = await Permission.bluetooth.status;
  if (blePermission.isDenied) {
    Permission.bluetooth.request();
  }

  if (Platform.isAndroid) {
    var bleConnectPermission = await Permission.bluetoothConnect.status;
    var bleScanPermission = await Permission.bluetoothScan.status;
    if (bleConnectPermission.isDenied) {
      Permission.bluetoothConnect.request();
    }
    if (bleScanPermission.isDenied) {
      Permission.bluetoothScan.request();
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future checkVersion() async {
    final bool check = await checkInternetConnection();

    if (check) {
      final res = await http.get(Uri.parse(Env.versionUrl));
      String resUtf8 = utf8.decode(res.bodyBytes);
      final version = box.read('version');

      if (resUtf8 != version) {
        final hub = await http.get(Uri.parse(Env.hubUrl));
        String bodyUtf8 = utf8.decode(hub.bodyBytes);
        box.write('hub', bodyUtf8);
        box.write('version', res.body);
      }
    }
  }

  Future startServer() async {
    final miniServer = MiniServer(
      host: 'localhost',
      port: 9090,
    );

    final String hub = box.read<String?>('hub') ?? '';

    miniServer.get("/", (HttpRequest httpRequest) async {
      final x = httpRequest.response;

      String charset = x.headers.contentType?.charset ?? "utf-8";

      x.headers.contentType = ContentType("text", "html", charset: charset);
      x.headers.add('Access-Control-Allow-Origin', '*');
      x.headers.add('Access-Control-Allow-Private-Network', "true");

      return x.write(hub);
    });
    if (hub.isNotEmpty) {
      Navigator.popAndPushNamed(context, "/hub");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text("Error internet connection!"),
      ));
    }
  }

  late final GetStorage box;

  Future<void> run() async {
    box = GetStorage();
    await initPermission();
    
    final String hub = box.read<String?>('hub') ?? '';
    if (hub.isEmpty) {
      await checkVersion();
    } else {
      checkVersion();
    }
    // or
    // await checkVersion();
    startServer();
  }

  @override
  void initState() {
    super.initState();
    run();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100)),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icons/app_icon.png',
                height: 100,
              ),
            ),
            const SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                color: Env.primColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
