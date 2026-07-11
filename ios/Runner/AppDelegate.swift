import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var pushToken: String?
  private var pendingPushTokenResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.hanaharmony.stockexchange/push",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "requestPushToken" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.requestPushToken(application, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func requestPushToken(_ application: UIApplication, result: @escaping FlutterResult) {
    if let pushToken {
      result(pushToken)
      return
    }
    guard pendingPushTokenResult == nil else {
      result(FlutterError(code: "PUSH_REGISTRATION_IN_PROGRESS", message: nil, details: nil))
      return
    }
    pendingPushTokenResult = result
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
      [weak self] granted, error in
      DispatchQueue.main.async {
        if let error {
          self?.finishPushRegistration(
            FlutterError(code: "PUSH_PERMISSION_FAILED", message: error.localizedDescription, details: nil)
          )
          return
        }
        guard granted else {
          self?.finishPushRegistration(
            FlutterError(code: "PUSH_PERMISSION_DENIED", message: nil, details: nil)
          )
          return
        }
        application.registerForRemoteNotifications()
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    pushToken = token
    finishPushRegistration(token)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    finishPushRegistration(
      FlutterError(code: "PUSH_REGISTRATION_FAILED", message: error.localizedDescription, details: nil)
    )
  }

  private func finishPushRegistration(_ value: Any?) {
    pendingPushTokenResult?(value)
    pendingPushTokenResult = nil
  }
}
