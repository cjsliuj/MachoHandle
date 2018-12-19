Pod::Spec.new do |s|
  s.name         = "MachoHandle"
  s.version      = "0.2"
  s.summary      = "MachoHandle"
  s.homepage     = "https://github.com/cjsliuj/MachoHandle"
  s.license      = "MIT"
  s.author             = { "cjsliuj@163.com" => "cjsliuj@163.com" }

  s.osx.deployment_target = "10.10"
  s.swift_version = '3.0'
  s.source       = { :git => "https://github.com/cjsliuj/MachoHandle.git", :tag => "#{s.version}" }
  s.source_files  = "Source/**/*.{swift,m,h}"
  s.public_header_files = 'Source/**/*.h'
end
