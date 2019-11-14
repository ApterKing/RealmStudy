# Uncomment the next line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'

target 'RealmStudy' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for RealmStudy
  pod 'RealmSwift', '= 3.14.0'

  target 'RealmStudyTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'RealmStudyUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings.delete('CODE_SIGNING_ALLOWED')
    config.build_settings.delete('CODE_SIGNING_REQUIRED')
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CONFIGURATION_BUILD_DIR'] = '$PODS_CONFIGURATION_BUILD_DIR'
    end
  end
end
