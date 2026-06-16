import 'package:share_bridge_core/share_bridge_core.dart';

void main() {
  final manager = ShareManager();
  print('registered channels: ${manager.registeredChannels.length}');
}
