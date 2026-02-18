import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'licenses.dart';
import 'log.dart';
import 'model/binding.dart';
import 'notifications/receive.dart';
import 'widgets/app.dart';
import 'widgets/share.dart';

// This library defines the Dart entrypoint function for headless FlutterEngine
// used in iOS Notification Service Extension. We need to import it here to
// for it to be included during the build process.
// ignore: unused_import
import 'notifications/ios_service.dart';

void main() {
  mainInit();
  runApp(const ZulipApp());
}

/// Everything [main] does short of [runApp].
///
/// This is useful for setup in Patrol-based integration tests.
void mainInit() {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());
  LicenseRegistry.addLicense(additionalLicenses);
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();
  NotificationService.instance.start();
  ShareService.start();
}
