Pod::Spec.new do |s|
  s.name         = "KKJSBridge"
  s.version      = "1.3.9"
  s.summary      = "One-stop solution for WKWebView to support offline resource，ajax/fetch request and cookie sync issues."
  s.description  = <<-DESC
                   One-stop solution for WKWebView to support offline resource，ajax/fetch request and cookie sync issues
                   DESC

  s.homepage     = "https://github.com/karosLi/KKJSBridge"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "Karosli" => "karosli1314@gmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/karosLi/KKJSBridge.git", :tag => "#{s.version}" }

  s.subspec 'Core' do |sub|
    sub.source_files  = "KKJSBridge/KKJSBridge/**/*.{h,m}"
    sub.exclude_files = "KKJSBridge/KKJSBridge/Modules/Ajax/AjaxHook/**/*.{h,m}","KKJSBridge/KKJSBridge/Modules/Ajax/AjaxProtocolHook/**/*.{h,m}"
  end

  s.subspec 'AjaxHook' do |sub|
    sub.source_files  = "KKJSBridge/KKJSBridge/Modules/Ajax/AjaxHook/**/*.{h,m}"
    sub.resources = "KKJSBridge/KKJSBridge/JS/KKJSBridgeAJAXHook.js"
    sub.dependency "KKJSBridge/Core"
    sub.user_target_xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) KKAjaxHook=1'
    }
    sub.pod_target_xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => 'KKAjaxHook=1'
    }
  end

  s.subspec 'AjaxProtocolHook' do |sub|
    sub.source_files  = "KKJSBridge/KKJSBridge/Modules/Ajax/AjaxProtocolHook/**/*.{h,m}"
    sub.resources = "KKJSBridge/KKJSBridge/JS/KKJSBridgeAJAXProtocolHook.js"
    sub.dependency "KKJSBridge/Core"
    sub.user_target_xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) KKAjaxProtocolHook=1'
    }
    sub.pod_target_xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => 'KKAjaxProtocolHook=1'
    }
  end

  s.default_subspecs = 'AjaxProtocolHook'
  s.frameworks = "WebKit", "UIKit"
  s.requires_arc = true

end
