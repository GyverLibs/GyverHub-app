import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Env {
  // release
  // static const versionUrl = "https://github.com/GyverLibs/GyverHub-web/releases/latest/download/version.txt";
  // static const hubUrl = "https://github.com/GyverLibs/GyverHub-web/releases/latest/download/GyverHub.html";

  // dev
  static const versionUrl =
      'https://raw.githubusercontent.com/GyverLibs/GyverHub-web/main/dist/version.txt';
  static const hubUrl =
      'https://raw.githubusercontent.com/GyverLibs/GyverHub-web/main/dist/GyverHub.html';

  static WebUri localServerUri = WebUri('http://localhost:9090/');
}
