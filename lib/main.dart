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
    AndroidDeviceInfo(:final sdkInt) => ('Android', '$sdkInt'), // '34'
    IosDeviceInfo(:final systemVersion) => ('iOS', systemVersion), // '17.4'
    MacOsDeviceInfo(:final osVersion) => ('macOS', osVersion), // '14.5.0'
    WindowsDeviceInfo() => ('Windows', ''),
    LinuxDeviceInfo() => ('Linux', ''),
    _ => ('', ''),
  };

  print('$osName, $osVersion');

  NotificationService.instance.start();
  runApp(const ZulipApp());
}
