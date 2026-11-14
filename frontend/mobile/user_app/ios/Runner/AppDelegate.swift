import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var contactChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NextLeadContact") else { return }
    contactChannel = FlutterMethodChannel(name: "nextlead/contact", binaryMessenger: registrar.messenger())
    contactChannel?.setMethodCallHandler { call, result in
      guard call.method == "open" else { result(FlutterMethodNotImplemented); return }
      guard let args = call.arguments as? [String: Any],
            let value = args["url"] as? String, let url = URL(string: value),
            url.scheme == "tel" || url.scheme == "sms" || (url.scheme == "https" && url.host == "wa.me") else {
        result(FlutterError(code: "INVALID_URL", message: "Unsupported contact action", details: nil))
        return
      }
      UIApplication.shared.open(url) { opened in
        result(opened ? nil : FlutterError(code: "UNAVAILABLE", message: "No app can open this contact action", details: nil))
      }
    }
  }
}
