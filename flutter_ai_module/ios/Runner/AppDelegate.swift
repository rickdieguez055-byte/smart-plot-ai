import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let shareChannel = FlutterMethodChannel(
      name: "com.smartplot.ai/share",
      binaryMessenger: controller.binaryMessenger
    )

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
          
          if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = controller.view
            popoverController.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
          }
          
          controller.present(activityVC, animated: true) {
            result(true)
          }
        } else {
          result(FlutterError(code: "FILE_NOT_FOUND", message: "Target file does not exist", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
