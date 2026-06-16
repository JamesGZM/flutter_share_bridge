import Flutter
import TencentOpenApi
import UIKit

public class ShareBridgeQqPlugin: NSObject, FlutterPlugin, QQApiInterfaceDelegate, TencentSessionDelegate {
  private static let shared = ShareBridgeQqPlugin()
  private static let callbackTimeout: TimeInterval = 120

  private var appId: String?
  private var universalLink: String?
  private var pendingResult: FlutterResult?
  private var pendingRequestId: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "share_bridge_qq", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(shared, channel: channel)
    registrar.addApplicationDelegate(shared)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      initialize(call, result: result)
    case "isInstalled":
      result(QQApiInterface.isQQInstalled() || QQApiInterface.isTIMInstalled())
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
    return QQApiInterface.handleOpen(url, delegate: self)
  }

  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]) -> Void
  ) -> Bool {
    guard let url = userActivity.webpageURL else {
      return false
    }
    return QQApiInterface.handleOpenUniversallink(url, delegate: self)
  }

  public static func handleOpen(_ url: URL) -> Bool {
    return QQApiInterface.handleOpen(url, delegate: shared)
  }

  public static func handleOpenUniversalLink(_ userActivity: NSUserActivity) -> Bool {
    guard let url = userActivity.webpageURL else {
      return false
    }
    return QQApiInterface.handleOpenUniversallink(url, delegate: shared)
  }

  public func onReq(_ req: QQBaseReq!) {}

  public func onResp(_ resp: QQBaseResp!) {
    completePending(mapResponse(resp))
  }

  public func isOnlineResponse(_ response: [AnyHashable: Any]!) {}

  public func tencentDidLogin() {}

  public func tencentDidNotLogin(_ cancelled: Bool) {}

  public func tencentDidNotNetWork() {}

  private func initialize(_ call: FlutterMethodCall, result: FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let appId = (arguments["appId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
          !appId.isEmpty
    else {
      result(FlutterError(code: "configError", message: "QQ appId 不能为空。", details: nil))
      return
    }

    let universalLink = arguments["universalLink"] as? String
    let privacyGranted = arguments["privacyGranted"] as? Bool ?? false
    TencentOAuth.setIsUserAgreedAuthorization(privacyGranted)
    TencentOAuth.sharedInstance().setupAppId(
      appId,
      enableUniveralLink: universalLink?.isEmpty == false,
      universalLink: universalLink,
      delegate: self
    )
    self.appId = appId
    self.universalLink = universalLink
    result(nil)
  }

  private func supports(_ call: FlutterMethodCall) -> Bool {
    guard let arguments = call.arguments as? [String: Any] else {
      return false
    }
    let channel = arguments["channel"] as? String
    let contentType = arguments["contentType"] as? String
    if channel == "qq.friend" {
      return contentType == "webpage" || contentType == "image"
    }
    if channel == "qq.qzone" {
      return contentType == "webpage"
    }
    return false
  }

  private func shareWebPage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(resultMap(code: "invalidArgument", message: "参数格式不正确。"))
      return
    }
    let title = arguments["title"] as? String ?? ""
    let description = arguments["description"] as? String ?? ""
    let urlValue = arguments["url"] as? String ?? ""
    guard !title.isEmpty, !description.isEmpty, let url = URL(string: urlValue) else {
      result(resultMap(code: "invalidArgument", message: "title、description、url 不能为空，且 url 必须合法。"))
      return
    }

    let previewData = previewImageData(path: arguments["thumbPath"] as? String)
    guard let object = QQApiURLObject(
      url: url,
      title: title,
      description: description,
      previewImageData: previewData,
      targetContentType: QQApiURLTargetType(rawValue: 3)!
    ) else {
      result(resultMap(code: "invalidArgument", message: "QQApiURLObject 创建失败。"))
      return
    }
    send(arguments: arguments, object: object, result: result)
  }

  private func shareImage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(resultMap(code: "invalidArgument", message: "参数格式不正确。"))
      return
    }
    let channel = arguments["channel"] as? String ?? ""
    if channel == "qq.qzone" {
      result(resultMap(code: "unsupportedContent", message: "QQ 空间纯图片分享暂不作为 iOS MVP 能力。"))
      return
    }
    let imagePath = arguments["imagePath"] as? String ?? ""
    guard !imagePath.isEmpty,
          FileManager.default.isReadableFile(atPath: imagePath),
          let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath))
    else {
      result(resultMap(code: "invalidArgument", message: "imagePath 必须指向可读文件。"))
      return
    }
    let previewData = previewImageData(path: arguments["thumbPath"] as? String) ?? imageData
    guard let object = QQApiImageObject(
      data: imageData,
      previewImageData: previewData,
      title: "",
      description: ""
    ) else {
      result(resultMap(code: "invalidArgument", message: "QQApiImageObject 创建失败。"))
      return
    }
    send(arguments: arguments, object: object, result: result)
  }

  private func send(
    arguments: [String: Any],
    object: QQApiObject,
    result: @escaping FlutterResult
  ) {
    guard appId != nil else {
      result(resultMap(code: "sdkNotInitialized", message: "QQ SDK 尚未初始化。"))
      return
    }
    guard QQApiInterface.isQQInstalled() || QQApiInterface.isTIMInstalled() else {
      result(resultMap(code: "appNotInstalled", message: "当前设备未安装 QQ 或 TIM。"))
      return
    }
    guard pendingResult == nil else {
      result(resultMap(code: "busy", message: "已有 QQ 分享请求等待回调。"))
      return
    }

    let requestId = arguments["requestId"] as? String ?? ""
    let channel = arguments["channel"] as? String ?? ""
    let request = SendMessageToQQReq(content: object)

    pendingResult = result
    pendingRequestId = requestId

    let sendCode: QQApiSendResultCode
    switch channel {
    case "qq.friend":
      sendCode = QQApiInterface.send(request)
    case "qq.qzone":
      sendCode = QQApiInterface.sendReq(toQZone: request)
    default:
      completePending(resultMap(code: "unsupportedChannel", message: "不支持的 QQ 渠道：\(channel)"))
      return
    }

    if sendCode.rawValue != 0 {
      completePending(resultMap(code: mapSendCode(sendCode), message: "QQApiInterface 发送失败：\(sendCode.rawValue)"))
      return
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
        self.resultMap(code: "timeout", message: "等待 QQ 回调超时。", requestId: requestId)
      )
    }
  }

  private func completePending(_ value: [String: Any?]) {
    let result = pendingResult
    pendingResult = nil
    pendingRequestId = nil
    result?(value)
  }

  private func previewImageData(path: String?) -> Data? {
    guard let path = path,
          !path.isEmpty,
          FileManager.default.isReadableFile(atPath: path)
    else {
      return nil
    }
    return try? Data(contentsOf: URL(fileURLWithPath: path))
  }

  private func mapResponse(_ resp: QQBaseResp?) -> [String: Any?] {
    guard let resp = resp else {
      return resultMap(code: "unknown", message: "QQ SDK 返回空响应。", requestId: pendingRequestId)
    }
    let code: String
    switch resp.result {
    case "0":
      code = "success"
    case "-4":
      code = "cancelled"
    case "-1", "-3", "-5":
      code = "nativeError"
    default:
      code = "unknown"
    }
    return resultMap(
      code: code,
      message: resp.errorDescription,
      requestId: pendingRequestId,
      raw: [
        "result": resp.result as Any,
        "type": resp.type,
        "extendInfo": resp.extendInfo as Any,
      ]
    )
  }

  private func mapSendCode(_ code: QQApiSendResultCode) -> String {
    switch code.rawValue {
    case 1, 11:
      return "appNotInstalled"
    case 2, 12, 10002, 10004:
      return "unsupportedContent"
    case 30001:
      return "permissionDenied"
    case 4, 5, 13, 20, 21, 22, 23, 24:
      return "invalidArgument"
    default:
      return "nativeError"
    }
  }

  private func resultMap(
    code: String,
    message: String?,
    requestId: String? = nil,
    raw: Any? = nil
  ) -> [String: Any?] {
    return [
      "requestId": requestId,
      "code": code,
      "message": message,
      "raw": raw,
    ]
  }
}
