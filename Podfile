use_frameworks!

target 'AsyncDisplayKitPlayground' do
  pod 'AsyncDisplayKit', :git => 'https://github.com/facebook/AsyncDisplayKit.git', :branch => 'master'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CONFIGURATION_BUILD_DIR'] = '$PODS_CONFIGURATION_BUILD_DIR'
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
