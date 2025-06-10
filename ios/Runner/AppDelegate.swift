import UIKit
import Flutter
import os.log

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  public var notificationHandler: NotificationHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    pluginRegistrant = self
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
    notificationHandler = NotificationHandler(registry.registrar(forPlugin: "zulip")!)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    notificationHandler!.handleNotificationTap(response: response)
    completionHandler()
  }
}

class NotificationHandler {
  private let pluginRegistrar: FlutterPluginRegistrar
  private var notificationTapEventListener: NotificationTapEventListener?

  init(_ pluginRegistrar: FlutterPluginRegistrar) {
    self.pluginRegistrar = pluginRegistrar
  }

  func setup(connectionOptions: UIScene.ConnectionOptions) {
    var notificationPayloadFromLaunch: [AnyHashable : Any]?
    if let response = connectionOptions.notificationResponse {
      if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
        notificationPayloadFromLaunch = response.notification.request.content.userInfo
      }
    }
    let api = NotificationHostApiImpl(notificationPayloadFromLaunch.map { NotificationDataFromLaunch(payload: $0) })
    NotificationHostApiSetup.setUp(binaryMessenger: pluginRegistrar.messenger(), api: api)
    
    notificationTapEventListener = NotificationTapEventListener()
    NotificationTapEventsStreamHandler.register(with: pluginRegistrar.messenger(), streamHandler: notificationTapEventListener!)
  }

  func handleNotificationTap(response: UNNotificationResponse) {
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      let userInfo = response.notification.request.content.userInfo
      notificationTapEventListener!.onNotificationTapEvent(payload: userInfo)
    }
  }
}

private class NotificationHostApiImpl: NotificationHostApi {
  private let maybeDataFromLaunch: NotificationDataFromLaunch?

  init(_ maybeDataFromLaunch: NotificationDataFromLaunch?) {
    self.maybeDataFromLaunch = maybeDataFromLaunch
  }

  func getNotificationDataFromLaunch() -> NotificationDataFromLaunch? {
    maybeDataFromLaunch
  }
}

// Adapted from Pigeon's Swift example for @EventChannelApi:
//   https://github.com/flutter/packages/blob/2dff6213a/packages/pigeon/example/app/ios/Runner/AppDelegate.swift#L49-L74
class NotificationTapEventListener: NotificationTapEventsStreamHandler {
  var eventSink: PigeonEventSink<NotificationTapEvent>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<NotificationTapEvent>) {
    eventSink = sink
  }

  func onNotificationTapEvent(payload: [AnyHashable : Any]) {
    eventSink?.success(NotificationTapEvent(payload: payload))
  }
}
