import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SmartPlotSharePlugin") else {
      return
    }
    let shareChannel = FlutterMethodChannel(name: "com.smartplot.ai/share", binaryMessenger: registrar.messenger())

    shareChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "shareFile" {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid file path", details: nil))
          return
        }

        if FileManager.default.fileExists(atPath: filePath) {
          let fileURL = URL(fileURLWithPath: filePath)
          let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

          if let rootVC = UIApplication.shared.connectedScenes
              .compactMap({ $0 as? UIWindowScene })
              .flatMap({ $0.windows })
              .first(where: { $0.isKeyWindow })?.rootViewController {

              var topVC = rootVC
              while let presented = topVC.presentedViewController {
                  topVC = presented
              }

              if let popover = activityVC.popoverPresentationController {
                  popover.sourceView = topVC.view
                  popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                  popover.permittedArrowDirections = []
              }
              topVC.present(activityVC, animated: true) {
                  result(true)
              }
          } else {
              result(FlutterError(code: "NO_ROOT_VC", message: "Could not find root view controller", details: nil))
          }
        } else {
          result(FlutterError(code: "FILE_NOT_FOUND", message: "Target file does not exist", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
