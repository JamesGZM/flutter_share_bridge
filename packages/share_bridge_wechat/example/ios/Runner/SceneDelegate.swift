import Flutter
import share_bridge_wechat_ios
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      if ShareBridgeWechatPlugin.handleOpen(context.url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if ShareBridgeWechatPlugin.handleOpenUniversalLink(userActivity) {
      return
    }
    super.scene(scene, continue: userActivity)
  }
}
