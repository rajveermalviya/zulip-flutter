import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }

    let notificationData = launchOptions?[.remoteNotification] as? [String : Any?]
    let api = IosNotificationApiImplementation(notificationData.map { NotificationDataJson(json: $0) })
    IosNotificationHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: api)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private class IosNotificationApiImplementation: IosNotificationHostApi {
  private let notificationDataFromLaunch: NotificationDataJson?

  init(_ notificationDataFromLaunch: NotificationDataJson?) {
    self.notificationDataFromLaunch = notificationDataFromLaunch
  }

  func getNotificationDataFromLaunch() -> NotificationDataJson? {
    notificationDataFromLaunch
  }
}
