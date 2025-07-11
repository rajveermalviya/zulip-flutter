// Autogenerated from Pigeon (v25.5.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

/// Error class for passing custom error details to Dart side.
final class PigeonError: Error {
  let code: String
  let message: String?
  let details: Sendable?

  init(code: String, message: String?, details: Sendable?) {
    self.code = code
    self.message = message
    self.details = details
  }

  var localizedDescription: String {
    return
      "PigeonError(code: \(code), message: \(message ?? "<nil>"), details: \(details ?? "<nil>")"
  }
}

private func wrapResult(_ result: Any?) -> [Any?] {
  return [result]
}

private func wrapError(_ error: Any) -> [Any?] {
  if let pigeonError = error as? PigeonError {
    return [
      pigeonError.code,
      pigeonError.message,
      pigeonError.details,
    ]
  }
  if let flutterError = error as? FlutterError {
    return [
      flutterError.code,
      flutterError.message,
      flutterError.details,
    ]
  }
  return [
    "\(error)",
    "\(type(of: error))",
    "Stacktrace: \(Thread.callStackSymbols)",
  ]
}

private func isNullish(_ value: Any?) -> Bool {
  return value is NSNull || value == nil
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

func deepEqualsNotifications(_ lhs: Any?, _ rhs: Any?) -> Bool {
  let cleanLhs = nilOrValue(lhs) as Any?
  let cleanRhs = nilOrValue(rhs) as Any?
  switch (cleanLhs, cleanRhs) {
  case (nil, nil):
    return true

  case (nil, _), (_, nil):
    return false

  case is (Void, Void):
    return true

  case let (cleanLhsHashable, cleanRhsHashable) as (AnyHashable, AnyHashable):
    return cleanLhsHashable == cleanRhsHashable

  case let (cleanLhsArray, cleanRhsArray) as ([Any?], [Any?]):
    guard cleanLhsArray.count == cleanRhsArray.count else { return false }
    for (index, element) in cleanLhsArray.enumerated() {
      if !deepEqualsNotifications(element, cleanRhsArray[index]) {
        return false
      }
    }
    return true

  case let (cleanLhsDictionary, cleanRhsDictionary) as ([AnyHashable: Any?], [AnyHashable: Any?]):
    guard cleanLhsDictionary.count == cleanRhsDictionary.count else { return false }
    for (key, cleanLhsValue) in cleanLhsDictionary {
      guard cleanRhsDictionary.index(forKey: key) != nil else { return false }
      if !deepEqualsNotifications(cleanLhsValue, cleanRhsDictionary[key]!) {
        return false
      }
    }
    return true

  default:
    // Any other type shouldn't be able to be used with pigeon. File an issue if you find this to be untrue.
    return false
  }
}

func deepHashNotifications(value: Any?, hasher: inout Hasher) {
  if let valueList = value as? [AnyHashable] {
     for item in valueList { deepHashNotifications(value: item, hasher: &hasher) }
     return
  }

  if let valueDict = value as? [AnyHashable: AnyHashable] {
    for key in valueDict.keys { 
      hasher.combine(key)
      deepHashNotifications(value: valueDict[key]!, hasher: &hasher)
    }
    return
  }

  if let hashableValue = value as? AnyHashable {
    hasher.combine(hashableValue.hashValue)
  }

  return hasher.combine(String(describing: value))
}

    

/// Generated class from Pigeon that represents data sent in messages.
struct NotificationDataFromLaunch: Hashable {
  /// The raw payload that is attached to the notification,
  /// holding the information required to carry out the navigation.
  ///
  /// See [NotificationHostApi.getNotificationDataFromLaunch].
  var payload: [AnyHashable?: Any?]


  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> NotificationDataFromLaunch? {
    let payload = pigeonVar_list[0] as! [AnyHashable?: Any?]

    return NotificationDataFromLaunch(
      payload: payload
    )
  }
  func toList() -> [Any?] {
    return [
      payload
    ]
  }
  static func == (lhs: NotificationDataFromLaunch, rhs: NotificationDataFromLaunch) -> Bool {
    return deepEqualsNotifications(lhs.toList(), rhs.toList())  }
  func hash(into hasher: inout Hasher) {
    deepHashNotifications(value: toList(), hasher: &hasher)
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct NotificationTapEvent: Hashable {
  /// The raw payload that is attached to the notification,
  /// holding the information required to carry out the navigation.
  ///
  /// See [notificationTapEvents].
  var payload: [AnyHashable?: Any?]


  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> NotificationTapEvent? {
    let payload = pigeonVar_list[0] as! [AnyHashable?: Any?]

    return NotificationTapEvent(
      payload: payload
    )
  }
  func toList() -> [Any?] {
    return [
      payload
    ]
  }
  static func == (lhs: NotificationTapEvent, rhs: NotificationTapEvent) -> Bool {
    return deepEqualsNotifications(lhs.toList(), rhs.toList())  }
  func hash(into hasher: inout Hasher) {
    deepHashNotifications(value: toList(), hasher: &hasher)
  }
}

private class NotificationsPigeonCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
    case 129:
      return NotificationDataFromLaunch.fromList(self.readValue() as! [Any?])
    case 130:
      return NotificationTapEvent.fromList(self.readValue() as! [Any?])
    default:
      return super.readValue(ofType: type)
    }
  }
}

private class NotificationsPigeonCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? NotificationDataFromLaunch {
      super.writeByte(129)
      super.writeValue(value.toList())
    } else if let value = value as? NotificationTapEvent {
      super.writeByte(130)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class NotificationsPigeonCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return NotificationsPigeonCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return NotificationsPigeonCodecWriter(data: data)
  }
}

class NotificationsPigeonCodec: FlutterStandardMessageCodec, @unchecked Sendable {
  static let shared = NotificationsPigeonCodec(readerWriter: NotificationsPigeonCodecReaderWriter())
}

var notificationsPigeonMethodCodec = FlutterStandardMethodCodec(readerWriter: NotificationsPigeonCodecReaderWriter());

/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol NotificationHostApi {
  /// Retrieves notification data if the app was launched by tapping on a notification.
  ///
  /// Returns `launchOptions.remoteNotification`,
  /// which is the raw APNs data dictionary
  /// if the app launch was opened by a notification tap,
  /// else null. See Apple doc:
  ///   https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey/remotenotification
  func getNotificationDataFromLaunch() throws -> NotificationDataFromLaunch?
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class NotificationHostApiSetup {
  static var codec: FlutterStandardMessageCodec { NotificationsPigeonCodec.shared }
  /// Sets up an instance of `NotificationHostApi` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: NotificationHostApi?, messageChannelSuffix: String = "") {
    let channelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
    /// Retrieves notification data if the app was launched by tapping on a notification.
    ///
    /// Returns `launchOptions.remoteNotification`,
    /// which is the raw APNs data dictionary
    /// if the app launch was opened by a notification tap,
    /// else null. See Apple doc:
    ///   https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey/remotenotification
    let getNotificationDataFromLaunchChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.zulip.NotificationHostApi.getNotificationDataFromLaunch\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      getNotificationDataFromLaunchChannel.setMessageHandler { _, reply in
        do {
          let result = try api.getNotificationDataFromLaunch()
          reply(wrapResult(result))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      getNotificationDataFromLaunchChannel.setMessageHandler(nil)
    }
  }
}

private class PigeonStreamHandler<ReturnType>: NSObject, FlutterStreamHandler {
  private let wrapper: PigeonEventChannelWrapper<ReturnType>
  private var pigeonSink: PigeonEventSink<ReturnType>? = nil

  init(wrapper: PigeonEventChannelWrapper<ReturnType>) {
    self.wrapper = wrapper
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    pigeonSink = PigeonEventSink<ReturnType>(events)
    wrapper.onListen(withArguments: arguments, sink: pigeonSink!)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    pigeonSink = nil
    wrapper.onCancel(withArguments: arguments)
    return nil
  }
}

class PigeonEventChannelWrapper<ReturnType> {
  func onListen(withArguments arguments: Any?, sink: PigeonEventSink<ReturnType>) {}
  func onCancel(withArguments arguments: Any?) {}
}

class PigeonEventSink<ReturnType> {
  private let sink: FlutterEventSink

  init(_ sink: @escaping FlutterEventSink) {
    self.sink = sink
  }

  func success(_ value: ReturnType) {
    sink(value)
  }

  func error(code: String, message: String?, details: Any?) {
    sink(FlutterError(code: code, message: message, details: details))
  }

  func endOfStream() {
    sink(FlutterEndOfEventStream)
  }

}

class NotificationTapEventsStreamHandler: PigeonEventChannelWrapper<NotificationTapEvent> {
  static func register(with messenger: FlutterBinaryMessenger,
                      instanceName: String = "",
                      streamHandler: NotificationTapEventsStreamHandler) {
    var channelName = "dev.flutter.pigeon.zulip.NotificationEventChannelApi.notificationTapEvents"
    if !instanceName.isEmpty {
      channelName += ".\(instanceName)"
    }
    let internalStreamHandler = PigeonStreamHandler<NotificationTapEvent>(wrapper: streamHandler)
    let channel = FlutterEventChannel(name: channelName, binaryMessenger: messenger, codec: notificationsPigeonMethodCodec)
    channel.setStreamHandler(internalStreamHandler)
  }
}
      
