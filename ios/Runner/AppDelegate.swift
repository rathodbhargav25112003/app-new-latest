import UIKit
import Flutter
import Firebase 
import OtplessSDK
import FirebaseCore
import ObjectiveC.runtime
// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }


@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate  {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    self.window?.makeSecure()
    Messaging.messaging().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
    } else {
        let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
    }
    application.registerForRemoteNotifications()
    UIPasteboard.blockCopy()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

   func application(application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
}
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        super.application(app, open: url, options: options)
        if Otpless.sharedInstance.isOtplessDeeplink(url: url){ Otpless.sharedInstance.processOtplessDeeplink(url: url) }
        return true
    }
}
extension UIWindow {
func makeSecure() {
    let field = UITextField()
    field.isSecureTextEntry = true
    self.addSubview(field)
    field.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    field.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    self.layer.superlayer?.addSublayer(field.layer)
    field.layer.sublayers?.first?.addSublayer(self.layer)
  }
}

extension UIPasteboard {
    static func blockCopy() {
        let originalStringSelector = #selector(setter: UIPasteboard.string)
        let swizzledStringSelector = #selector(UIPasteboard.swizzled_setString(_:))
        let originalItemsSelector = #selector(setter: UIPasteboard.items)
        let swizzledItemsSelector = #selector(UIPasteboard.swizzled_setItems(_:))

        if let originalStringMethod = class_getInstanceMethod(UIPasteboard.self, originalStringSelector),
           let swizzledStringMethod = class_getInstanceMethod(UIPasteboard.self, swizzledStringSelector) {
            method_exchangeImplementations(originalStringMethod, swizzledStringMethod)
        }
        if let originalItemsMethod = class_getInstanceMethod(UIPasteboard.self, originalItemsSelector),
           let swizzledItemsMethod = class_getInstanceMethod(UIPasteboard.self, swizzledItemsSelector) {
            method_exchangeImplementations(originalItemsMethod, swizzledItemsMethod)
        }
    }

    @objc func swizzled_setString(_ string: String?) {
        self.swizzled_setString("")
    }

    @objc func swizzled_setItems(_ items: [[String: Any]]) {
        self.swizzled_setItems([[:]]) // Set empty items
    }
}
