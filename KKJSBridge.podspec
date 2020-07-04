Pod::Spec.new do |s|
  s.name         = "KKJSBridge"
  s.version      = "1.1.5-beta3"
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

  s.source_files  = "KKJSBridge/KKJSBridge/**/*.{h,m}"
  s.resources = "KKJSBridge/KKJSBridge/JS/*.js"

  s.frameworks = "WebKit", "UIKit"
  s.requires_arc = true

end
