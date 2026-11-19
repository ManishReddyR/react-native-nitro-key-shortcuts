require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "NitroKeyShortcuts"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"] || "https://www.npmjs.com/package/react-native-nitro-key-shortcuts"
  s.license      = package["license"]
  s.authors      = package["author"] || "react-native-nitro-key-shortcuts contributors"

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :path => "." }

  s.source_files = [
    "ios/**/*.{swift}",
    "ios/**/*.{h,m,mm}",
  ]

  load 'nitrogen/generated/ios/NitroKeyShortcuts+autolinking.rb'
  add_nitrogen_files(s)

  s.dependency 'React-jsi'
  s.dependency 'React-callinvoker'
  install_modules_dependencies(s)
end
