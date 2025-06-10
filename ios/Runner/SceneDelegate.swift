import UIKit
import Flutter
import os.log

@objc class SceneDelegate : FlutterSceneDelegate {
  override
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let notificationHandler = appDelegate.notificationHandler!
    notificationHandler.setup(connectionOptions: connectionOptions)

    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
