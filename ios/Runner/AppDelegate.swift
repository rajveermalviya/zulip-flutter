import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var notificationTapEventListener: NotificationTapEventListener?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }

    let notificationData = launchOptions?[.remoteNotification] as? [AnyHashable : Any]
    let api = IosNotificationApiImpl(notificationData.map { NotificationDataJson(json: $0) })
    IosNotificationHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: api)

    notificationTapEventListener = NotificationTapEventListener()
    NotificationTapEventsStreamHandler.register(with: controller.binaryMessenger, streamHandler: notificationTapEventListener!)

    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let listener = notificationTapEventListener {
      let userInfo = response.notification.request.content.userInfo
      listener.onNotificationTapEvent(data: NotificationDataJson(json: userInfo))
      completionHandler()
    }
  }
}

private class IosNotificationApiImpl: IosNotificationHostApi {
  private let notificationDataFromLaunch: NotificationDataJson?

  init(_ notificationDataFromLaunch: NotificationDataJson?) {
    self.notificationDataFromLaunch = notificationDataFromLaunch
  }

  func getNotificationDataFromLaunch() -> NotificationDataJson? {
    notificationDataFromLaunch
  }
}

class NotificationTapEventListener: NotificationTapEventsStreamHandler {
  var eventSink: PigeonEventSink<NotificationDataJson>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<NotificationDataJson>) {
    eventSink = sink
  }

  func onNotificationTapEvent(data: NotificationDataJson) {
    if let eventSink = eventSink {
      eventSink.success(data)
    }
  }

  func onEventsDone() {
    eventSink?.endOfStream()
    eventSink = nil
  }
}
