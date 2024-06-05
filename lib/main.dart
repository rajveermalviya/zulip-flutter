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

  final (osName, osVariant) = switch (deviceInfo) {
    AndroidDeviceInfo(
      :var sdkInt)        => ('Android', '$sdkInt'), // "34"
    IosDeviceInfo(
      :var systemVersion) => ('iOS', systemVersion), // "17.4"
    MacOsDeviceInfo(
      :var majorVersion,
      :var minorVersion,
      :var patchVersion)  => ('macOS', '$majorVersion.$minorVersion.$patchVersion'), // "14.5.0"
    WindowsDeviceInfo(
      :var majorVersion,
      :var minorVersion,
      :var buildNumber)   => ('Windows', '$majorVersion.$minorVersion.$buildNumber'), // "10.0 22631" means Windows 11, 23H2
    LinuxDeviceInfo(
      :var name,
      :var versionId)     => ('Linux', '$name${versionId != null ? ' $versionId' : ''}'), // "Fedora 40" or "Fedora"
    _                     => ('', ''),
  };

  print('$osName, $osVariant');

  NotificationService.instance.start();
  runApp(const ZulipApp());
}
