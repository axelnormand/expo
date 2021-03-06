# coding: utf-8
require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))
version = package['version']

source = { :git => 'https://github.com/facebook/react-native.git' }
if version == '1000.0.0'
  # This is an unpublished version, use the latest commit hash of the react-native repo, which we’re presumably in.
  source[:commit] = `git rev-parse HEAD`.strip
else
  source[:tag] = "v#{version}"
end

folly_compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1'

Pod::Spec.new do |s|
  s.name                    = "ReactABI22_0_0"
  s.version                 = version
  s.summary                 = package["description"]
  s.description             = <<-DESC
                                React Native apps are built using the React JS
                                framework, and render directly to native UIKit
                                elements using a fully asynchronous architecture.
                                There is no browser and no HTML. We have picked what
                                we think is the best set of features from these and
                                other technologies to build what we hope to become
                                the best product development framework available,
                                with an emphasis on iteration speed, developer
                                delight, continuity of technology, and absolutely
                                beautiful and fast products with no compromises in
                                quality or capability.
                             DESC
  s.homepage                = "http://facebook.github.io/react-native/"
  s.license                 = package["license"]
  s.author                  = "Facebook"
  s.source                  = { :path => "." }
  s.default_subspec         = "Core"
  s.requires_arc            = true
  s.platforms               = { :ios => "8.0", :tvos => "9.2" }
  s.pod_target_xcconfig     = { "CLANG_CXX_LANGUAGE_STANDARD" => "c++14" }
  s.preserve_paths          = "package.json", "LICENSE", "LICENSE-docs", "PATENTS"
  s.cocoapods_version       = ">= 1.2.0"

  s.subspec "Core" do |ss|
    ss.dependency             "yogaABI22_0_0", "#{package["version"]}.React"
    ss.source_files         = "React/**/*.{c,h,m,mm,S}"
    ss.exclude_files        = "**/__tests__/*",
                              "IntegrationTests/*",
                              "React/DevSupport/*",
                              "React/Inspector/*",
                              "ReactCommon/ABI22_0_0yoga/*",
                              "React/Cxx*/*",
                              "React/Base/ABI22_0_0RCTBatchedBridge.mm",
                              "React/Executors/*"
    ss.ios.exclude_files    = "React/**/ABI22_0_0RCTTVView.*"
    ss.tvos.exclude_files   = "React/Modules/RCTClipboard*",
                              "React/Views/RCTDatePicker*",
                              "React/Views/RCTPicker*",
                              "React/Views/RCTRefreshControl*",
                              "React/Views/RCTSlider*",
                              "React/Views/RCTSwitch*",
                              "React/Views/RCTWebView*"
    ss.header_dir           = "ABI22_0_0React"
    ss.framework            = "JavaScriptCore"
    ss.libraries            = "stdc++"
    ss.pod_target_xcconfig  = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ReactCommon\"" }
  end

  s.subspec "Expo" do |ss|
    ss.dependency         "ReactABI22_0_0/Core"
    ss.dependency 'Amplitude-iOS'
    ss.dependency 'Analytics'
    ss.dependency 'AppAuth'
    ss.dependency 'FBAudienceNetwork'
    ss.dependency 'FBSDKCoreKit'
    ss.dependency 'FBSDKLoginKit'
    ss.dependency 'FBSDKShareKit'
    ss.dependency 'Google-Mobile-Ads-SDK'
    ss.dependency 'GoogleSignIn'
    ss.dependency 'GoogleMaps'
    ss.dependency 'GPUImage'
    ss.dependency 'lottie-ios'
    ss.dependency 'JKBigInteger2'
    ss.dependency 'Branch'
    ss.source_files     = "Expo/Core/**/*.{h,m}"
  end

  s.subspec "ExpoOptional" do |ss|
    ss.dependency         "ReactABI22_0_0/Expo"
    ss.source_files     = "Expo/Optional/**/*.{h,m}"
  end

  s.subspec "BatchedBridge" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.dependency             "ReactABI22_0_0/cxxReactABI22_0_0_legacy"
    ss.source_files         = "React/Base/ABI22_0_0RCTBatchedBridge.mm", "React/Executors/*"
  end

  s.subspec "CxxBridge" do |ss|
    ss.dependency             "Folly", "2016.09.26.00"
    ss.dependency             "ReactABI22_0_0/Core"
    ss.dependency             "ReactABI22_0_0/cxxReactABI22_0_0"
    ss.compiler_flags       = folly_compiler_flags
    ss.private_header_files = "React/Cxx*/*.h"
    ss.source_files         = "React/Cxx*/*.{h,m,mm}"
  end

  s.subspec "DevSupport" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.dependency             "ReactABI22_0_0/RCTWebSocket"
    ss.source_files         = "React/DevSupport/*",
                              "React/Inspector/*"
  end

  s.subspec "tvOS" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "React/**/RCTTVView.{h, m}"
  end

  s.subspec "ABI22_0_0jschelpers_legacy" do |ss|
    ss.source_files         = "ReactCommon/ABI22_0_0jschelpers/ABI22_0_0{JavaScriptCore,JSCWrapper,InspectorInterfaces}.{cpp,h}", "ReactCommon/ABI22_0_0jschelpers/ABI22_0_0systemJSCWrapper.cpp"
    ss.private_header_files = "ReactCommon/ABI22_0_0jschelpers/ABI22_0_0{JavaScriptCore,JSCWrapper,InspectorInterfaces}.h"
    ss.pod_target_xcconfig  = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ReactCommon\"" }
    ss.framework            = "JavaScriptCore"
  end

  s.subspec "cxxReactABI22_0_0_legacy" do |ss|
    ss.dependency             "ReactABI22_0_0/ABI22_0_0jschelpers_legacy"
    ss.source_files         = "ReactCommon/cxxReactABI22_0_0/ABI22_0_0{JSBundleType,oss-compat-util}.{cpp,h}"
    ss.private_header_files = "ReactCommon/cxxReactABI22_0_0/ABI22_0_0{JSBundleType,oss-compat-util}.h"
    ss.pod_target_xcconfig  = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ReactCommon\"" }
  end

  s.subspec "ABI22_0_0jschelpers" do |ss|
    ss.dependency             "Folly", "2016.09.26.00"
    ss.compiler_flags       = folly_compiler_flags
    ss.source_files         = "ReactCommon/ABI22_0_0jschelpers/*.{cpp,h}"
    ss.private_header_files = "ReactCommon/ABI22_0_0jschelpers/*.h"
    ss.pod_target_xcconfig  = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ReactCommon\"" }
    ss.framework            = "JavaScriptCore"
  end

  s.subspec "cxxReactABI22_0_0" do |ss|
    ss.dependency             "ReactABI22_0_0/ABI22_0_0jschelpers"
    ss.dependency             "boost-for-react-native", "1.63.0"
    ss.dependency             "Folly", "2016.09.26.00"
    ss.compiler_flags       = folly_compiler_flags
    ss.source_files         = "ReactCommon/cxxReactABI22_0_0/*.{cpp,h}"
    ss.exclude_files        = "ReactCommon/cxxReactABI22_0_0/ABI22_0_0SampleCxxModule.*"
    ss.private_header_files = "ReactCommon/cxxReactABI22_0_0/*.h"
    ss.pod_target_xcconfig  = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ReactCommon\" \"$(PODS_ROOT)/boost-for-react-native\" \"$(PODS_ROOT)/DoubleConversion\" \"$(PODS_ROOT)/Folly\"" }
  end

  s.subspec "ART" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/ART/**/*.{h,m}"
  end

  s.subspec "RCTActionSheet" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/ActionSheetIOS/*.{h,m}"
  end

  s.subspec "RCTAdSupport" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/AdSupport/*.{h,m}"
  end

  s.subspec "RCTAnimation" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/NativeAnimation/{Drivers/*,Nodes/*,*}.{h,m}"
    ss.header_dir           = "ABI22_0_0RCTAnimation"
  end

  s.subspec "RCTBlob" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/Blob/*.{h,m}"
    ss.preserve_paths       = "Libraries/Blob/*.js"
  end

  s.subspec "RCTCameraRoll" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.dependency             'React/RCTImage'
    ss.source_files         = "Libraries/CameraRoll/*.{h,m}"
  end

  s.subspec "RCTGeolocation" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/Geolocation/*.{h,m}"
  end

  s.subspec "RCTImage" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.dependency             "ReactABI22_0_0/RCTNetwork"
    ss.source_files         = "Libraries/Image/*.{h,m}"
  end

  s.subspec "RCTNetwork" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/Network/*.{h,m,mm}"
  end

  s.subspec "RCTPushNotification" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/PushNotificationIOS/*.{h,m}"
  end

  s.subspec "RCTSettings" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/Settings/*.{h,m}"
  end

  s.subspec "RCTText" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/Text/*.{h,m}"
  end

  s.subspec "RCTVibration" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/Vibration/*.{h,m}"
  end

  s.subspec "RCTWebSocket" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.dependency             "ReactABI22_0_0/RCTBlob"
    ss.dependency             "ReactABI22_0_0/fishhook"
    ss.source_files         = "Libraries/WebSocket/*.{h,m}"
  end

  s.subspec "fishhook" do |ss|
    ss.header_dir           = "fishhook"
    ss.source_files         = "Libraries/fishhook/*.{h,c}"
  end

  s.subspec "RCTLinkingIOS" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/LinkingIOS/*.{h,m}"
  end

  s.subspec "RCTTest" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.source_files         = "Libraries/RCTTest/**/*.{h,m}"
    ss.frameworks           = "XCTest"
  end

  s.subspec "_ignore_me_subspec_for_linting_" do |ss|
    ss.dependency             "ReactABI22_0_0/Core"
    ss.dependency             "ReactABI22_0_0/CxxBridge"
  end
end
