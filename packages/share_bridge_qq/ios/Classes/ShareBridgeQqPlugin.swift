import Flutter
import UIKit

public class ShareBridgeQqPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "share_bridge_qq", binaryMessenger: registrar.messenger())
    let instance = ShareBridgeQqPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      result(nil)
    case "isInstalled":
      result(false)
    case "supports":
      result(false)
    case "shareWebPage", "shareImage":
      result([
        "code": "unsupportedContent",
        "message": "QQ native SDK integration is not implemented yet."
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
