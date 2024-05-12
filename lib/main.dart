import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:gyver_hub/core/theme.dart';
import '../pages/splash_screen.dart';
import '../pages/hub_view.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(false);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GyverHub',
      themeMode: ThemeMode.light,
      darkTheme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: CustomColors.primary),
        scaffoldBackgroundColor: CustomColors.darkBackground,
        splashColor: CustomColors.darkBackground,
      ),
      initialRoute: '/splash-screen',
      routes: {
        '/splash-screen': (ctx) => const SplashScreen(),
        '/hub': (ctx) => HubView(),
      },
    );
  }
}
