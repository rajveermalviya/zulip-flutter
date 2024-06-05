import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'licenses.dart';
import 'log.dart';
import 'model/binding.dart';
import 'notifications/receive.dart';
import 'widgets/app.dart';

Future<void> main() async {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());
  LicenseRegistry.addLicense(additionalLicenses);
  WidgetsFlutterBinding.ensureInitialized();
  await LiveZulipBinding.ensureInitialized();
  final packageInfo = ZulipBinding.instance.packageInfo;
  final deviceInfo = ZulipBinding.instance.deviceInfo;

  final (osName, osVersion) = switch (deviceInfo) {
    AndroidDeviceInfo(:final sdkInt) => ('Android', '$sdkInt'),
    IosDeviceInfo(:final systemVersion) => ('iOS', systemVersion),
    MacOsDeviceInfo(:final osRelease) => ('macOS', osRelease),
    WindowsDeviceInfo() => ('Windows', ''),
    LinuxDeviceInfo() => ('Linux', ''),
    _ => ('', ''),
  };

  print('$osName, $osVersion');

  NotificationService.instance.start();
  runApp(const ZulipApp());
}
