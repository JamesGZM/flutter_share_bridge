import Flutter
import UIKit
import WechatOpenSDK

public class ShareBridgeWechatPlugin: NSObject, FlutterPlugin, WXApiDelegate {
  private static let shared = ShareBridgeWechatPlugin()
  private static let callbackTimeout: TimeInterval = 120
  private static let maxThumbBytes = 32 * 1024

  private var appId: String?
  private var pendingResult: FlutterResult?
  private var pendingRequestId: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "share_bridge_wechat",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(shared, channel: channel)
    registrar.addApplicationDelegate(shared)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      initialize(call, result: result)
    case "isInstalled":
      result(WXApi.isWXAppInstalled())
    case "supports":
      result(supports(call))
    case "shareWebPage":
      shareWebPage(call, result: result)
    case "shareImage":
      shareImage(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return WXApi.handleOpen(url, delegate: self)
  }

  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]) -> Void
  ) -> Bool {
    return WXApi.handleOpenUniversalLink(userActivity, delegate: self)
  }

  public func onReq(_ req: BaseReq) {}

  public func onResp(_ resp: BaseResp) {
    completePending(mapResponse(resp))
  }

  public static func handleOpen(_ url: URL) -> Bool {
    return WXApi.handleOpen(url, delegate: shared)
  }

  public static func handleOpenUniversalLink(_ userActivity: NSUserActivity) -> Bool {
    return WXApi.handleOpenUniversalLink(userActivity, delegate: shared)
  }

  private func initialize(_ call: FlutterMethodCall, result: FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let appId = (arguments["appId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
          !appId.isEmpty
    else {
      result(FlutterError(code: "configError", message: "微信 appId 不能为空。", details: nil))
      return
    }

    let universalLink = arguments["universalLink"] as? String
    let registered = WXApi.registerApp(appId, universalLink: universalLink ?? "")
    if !registered {
      result(FlutterError(code: "configError", message: "WXApi.registerApp 返回 false。", details: nil))
      return
    }
    self.appId = appId
    result(nil)
  }

  private func supports(_ call: FlutterMethodCall) -> Bool {
    guard let arguments = call.arguments as? [String: Any] else {
      return false
    }
    let channel = arguments["channel"] as? String
    let contentType = arguments["contentType"] as? String
    return ["wechat.session", "wechat.timeline"].contains(channel) &&
      ["webpage", "image"].contains(contentType)
  }

  private func shareWebPage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(resultMap(code: "invalidArgument", message: "参数格式不正确。"))
      return
    }
    let title = arguments["title"] as? String ?? ""
    let description = arguments["description"] as? String ?? ""
    let url = arguments["url"] as? String ?? ""
    if title.isEmpty || description.isEmpty || url.isEmpty {
      result(resultMap(code: "invalidArgument", message: "title、description、url 不能为空。"))
      return
    }

    let webpage = WXWebpageObject()
    webpage.webpageUrl = url

    let message = WXMediaMessage()
    message.title = title
    message.description = description
    message.mediaObject = webpage
    if let thumbnail = imageData(arguments["thumbnail"]) {
      setThumbImage(message: message, data: thumbnail)
    }

    sendMessage(arguments: arguments, message: message, result: result)
  }

  private func shareImage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(resultMap(code: "invalidArgument", message: "参数格式不正确。"))
      return
    }
    guard let imageData = imageData(arguments["image"]) else {
      result(resultMap(code: "invalidArgument", message: "image 必须是可读文件或非空字节。"))
      return
    }

    let image = WXImageObject()
    image.imageData = imageData

    let message = WXMediaMessage()
    message.mediaObject = image
    if let thumbnail = self.imageData(arguments["thumbnail"]) {
      setThumbImage(message: message, data: thumbnail)
    } else {
      setThumbImage(message: message, data: imageData)
    }

    sendMessage(arguments: arguments, message: message, result: result)
  }

  private func sendMessage(
    arguments: [String: Any],
    message: WXMediaMessage,
    result: @escaping FlutterResult
  ) {
    guard appId != nil else {
      result(resultMap(code: "sdkNotInitialized", message: "微信 SDK 尚未初始化。"))
      return
    }
    guard WXApi.isWXAppInstalled() else {
      result(resultMap(code: "appNotInstalled", message: "当前设备未安装微信。"))
      return
    }
    guard pendingResult == nil else {
      result(resultMap(code: "busy", message: "已有微信分享请求等待回调。"))
      return
    }

    let requestId = arguments["requestId"] as? String ?? ""
    let channel = arguments["channel"] as? String ?? ""
    let scene: Int32
    switch channel {
    case "wechat.session":
      scene = 0
    case "wechat.timeline":
      scene = 1
    default:
      result(resultMap(code: "unsupportedChannel", message: "不支持的微信渠道：\(channel)"))
      return
    }

    let request = SendMessageToWXReq()
    request.bText = false
    request.message = message
    request.scene = scene

    pendingResult = result
    pendingRequestId = requestId

    WXApi.send(request) { [weak self] sent in
      guard let self = self else {
        return
      }
      if !sent {
        self.completePending(self.resultMap(code: "nativeError", message: "WXApi.sendReq 返回 false。"))
      }
    }

    scheduleTimeout(requestId: requestId)
  }

  private func scheduleTimeout(requestId: String) {
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.callbackTimeout) { [weak self] in
      guard let self = self,
            self.pendingRequestId == requestId,
            self.pendingResult != nil
      else {
        return
      }
      self.completePending(
        self.resultMap(code: "timeout", message: "等待微信回调超时。", requestId: requestId)
      )
    }
  }

  private func completePending(_ value: [String: Any?]) {
    let result = pendingResult
    pendingResult = nil
    pendingRequestId = nil
    result?(value)
  }

  private func imageData(_ value: Any?) -> Data? {
    guard let source = value as? [String: Any],
          let type = source["type"] as? String
    else {
      return nil
    }
    if type == "file",
       let path = source["path"] as? String,
       !path.isEmpty,
       FileManager.default.isReadableFile(atPath: path) {
      return try? Data(contentsOf: URL(fileURLWithPath: path))
    }
    if type == "memory",
       let data = source["bytes"] as? FlutterStandardTypedData,
       !data.data.isEmpty {
      return data.data
    }
    return nil
  }

  private func setThumbImage(message: WXMediaMessage, data: Data) {
    guard let image = UIImage(data: data) else {
      return
    }
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120))
    let resized = renderer.image { _ in
      image.draw(in: CGRect(x: 0, y: 0, width: 120, height: 120))
    }
    message.setThumbImage(resized)
  }

  private func mapResponse(_ resp: BaseResp) -> [String: Any?] {
    let code: String
    switch resp.errCode {
    case 0:
      code = "success"
    case -2:
      code = "cancelled"
    case -4:
      code = "permissionDenied"
    case -5:
      code = "unsupportedContent"
    case -1, -3:
      code = "nativeError"
    default:
      code = "unknown"
    }
    return resultMap(code: code, message: resp.errStr, requestId: pendingRequestId)
  }

  private func resultMap(
    code: String,
    message: String?,
    requestId: String? = nil
  ) -> [String: Any?] {
    return [
      "requestId": requestId,
      "code": code,
      "message": message,
    ]
  }
}
