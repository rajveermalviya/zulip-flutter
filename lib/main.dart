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
    AndroidDeviceInfo() => ('Android', '${deviceInfo.sdkInt}'), // '34'
    IosDeviceInfo()     => ('iOS', deviceInfo.systemVersion), // '17.4'
    MacOsDeviceInfo()   => ('macOS', '${deviceInfo.majorVersion}'
                                      '.${deviceInfo.minorVersion}'
                                      '.${deviceInfo.patchVersion}'), // '14.5.0'
    WindowsDeviceInfo() => ('Windows', '${deviceInfo.majorVersion}'
                                        '.${deviceInfo.minorVersion}'
                                        ' ${deviceInfo.buildNumber}'), // '10.0 22631' means Windows 11, 23H2
    LinuxDeviceInfo()   => ('Linux', ''),
    _                   => ('', ''),
  };

  print('$osName, $osVersion');

  NotificationService.instance.start();
  runApp(const ZulipApp());
}
