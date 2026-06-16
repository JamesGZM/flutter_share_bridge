import Flutter
import UIKit

public class ShareBridgeWechatPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "share_bridge_wechat", binaryMessenger: registrar.messenger())
    let instance = ShareBridgeWechatPlugin()
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
        "message": "WeChat native SDK integration is not implemented yet."
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
