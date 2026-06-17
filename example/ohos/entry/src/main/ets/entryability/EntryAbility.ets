
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import ShareBridgeWechatPlugin from 'share_bridge_wechat_ohos';
import ShareBridgeQqPlugin from 'share_bridge_qq_ohos';

export default class EntryAbility extends FlutterAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    super.onCreate(want, launchParam)
    ShareBridgeWechatPlugin.handleWant(want)
    ShareBridgeQqPlugin.handleWant(want)
  }

  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParams)
    ShareBridgeWechatPlugin.handleWant(want)
    ShareBridgeQqPlugin.handleWant(want)
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
