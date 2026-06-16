import Flutter
import share_bridge_qq
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      if ShareBridgeQqPlugin.handleOpen(context.url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if ShareBridgeQqPlugin.handleOpenUniversalLink(userActivity) {
      return
    }
    super.scene(scene, continue: userActivity)
  }
}
