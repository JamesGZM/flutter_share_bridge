#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint share_bridge_qq_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'share_bridge_qq_ios'
  s.version          = '0.1.0-dev.1'
  s.summary          = 'Share Bridge QQ and QZone plugin.'
  s.description      = <<-DESC
Share Bridge QQ and QZone share plugin.
                       DESC
  s.homepage         = 'https://github.com/gongziming/flutter_share_bridge'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'gongziming' => 'gongziming@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/TencentOpenAPI.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'UIKit', 'Foundation', 'Security', 'SystemConfiguration', 'CoreTelephony', 'WebKit'
  s.libraries = 'z', 'sqlite3', 'c++'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'share_bridge_qq_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
