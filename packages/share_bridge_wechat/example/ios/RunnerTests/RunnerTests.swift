import Flutter
import UIKit
import XCTest


@testable import share_bridge_wechat_ios

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testIsInstalledReturnsFalseUntilSdkIsIntegrated() {
    let plugin = ShareBridgeWechatPlugin()

    let call = FlutterMethodCall(methodName: "isInstalled", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! Bool, false)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
