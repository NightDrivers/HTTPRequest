Pod::Spec.new do |s|
  s.name         = "HTTPRequest"
  s.version      = "1.0.2"
  s.summary      = "Alamofire简单封装"
  s.swift_version = "5.0"
  s.description  = <<-DESC
  "Alamofire简单封装，支持基本的网络请求"
                   DESC
  s.homepage = 'ssh://lindc@10.10.2.2:29418/~lindc/HTTPRequest.git'
  s.license      = "MIT"
  s.author       = { "NightDriver" => "lin_de_chun@sina.com" }
  s.source       = { :git => "ssh://lindc@10.10.2.2:29418/~lindc/HTTPRequest.git", :tag => "#{s.version}" }
  s.resources    = ['HTTPRequest/*.lproj/*']
  s.source_files  = "HTTPRequest/*.swift"
  s.ios.deployment_target = '10.0'
  s.dependency "Alamofire"
  s.dependency "SwiftyJSON"
  s.dependency "BaseKitSwift"
end
