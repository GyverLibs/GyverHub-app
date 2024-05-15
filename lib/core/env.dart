import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:gyver_hub/core/enums.dart';

class Env {
  // change this value to switch env
  static const buildMode = BuildMode.dev;

  static String get versionUrl => buildMode == BuildMode.release
      ? _Consts.releaseVersionUrl
      : _Consts.devVersionUrl;
  static String get hubUrl => buildMode == BuildMode.release
      ? _Consts.releaseHubUrl
      : _Consts.devHubUrl;
  static WebUri localServerUri = WebUri('http://localhost:9090/');
}

class _Consts {
  static const releaseVersionUrl =
      'https://github.com/GyverLibs/GyverHub-web/releases/latest/download/version.txt';
  static const releaseHubUrl =
      'https://github.com/GyverLibs/GyverHub-web/releases/latest/download/GyverHub.html';
  static const devVersionUrl =
      'https://raw.githubusercontent.com/GyverLibs/GyverHub-web/main/dist/version.txt';
  static const devHubUrl =
      'https://raw.githubusercontent.com/GyverLibs/GyverHub-web/main/dist/GyverHub.html';
}
