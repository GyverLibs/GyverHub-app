import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gyver_hub/core/env.dart';
import 'package:gyver_hub/core/theme.dart';
import 'package:mini_server/mini_server_package.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'package:gyver_hub/core/helpers.dart';

Future initPermission() async {
  await GetStorage.init();
  await Permission.storage.request();
  await Permission.location.request();
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future checkVersion() async {
    final check = await Helpers.checkInternetConnection();

    if (check) {
      final res = await http.get(Uri.parse(Env.versionUrl));
      final resUtf8 = utf8.decode(res.bodyBytes);
      final version = _storage.read('version');

      if (resUtf8 != version) {
        final hub = await http.get(Uri.parse(Env.hubUrl));
        final bodyUtf8 = utf8.decode(hub.bodyBytes);
        _storage.write('hub', bodyUtf8);
        _storage.write('version', res.body);
      }
    }
  }

  Future startServer() async {
    final miniServer = MiniServer(
      host: Env.localServerUri.host,
      port: Env.localServerUri.port,
    );

    final hub = _storage.read<String?>('hub') ?? '';

    miniServer.get('/', (HttpRequest httpRequest) async {
      final x = httpRequest.response;

      final charset = x.headers.contentType?.charset ?? 'utf-8';

      x.headers.contentType = ContentType('text', 'html', charset: charset);
      x.headers.add('Access-Control-Allow-Origin', '*');
      x.headers.add('Access-Control-Allow-Private-Network', 'true');

      return x.write(hub);
    });
    if (hub.isNotEmpty) {
      Navigator.popAndPushNamed(context, '/hub');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: CustomColors.error,
          content: Text('Error internet connection!'),
        ),
      );
    }
  }

  late final GetStorage _storage;

  Future<void> run() async {
    _storage = GetStorage();
    await initPermission();

    final hub = _storage.read<String?>('hub') ?? '';
    if (hub.isEmpty) {
      await checkVersion();
    } else {
      checkVersion();
    }
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
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(100)),
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
                color: CustomColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
