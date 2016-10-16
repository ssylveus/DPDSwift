# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'DPDSwift' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  post_install do |installer|
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '2.3'
            end
        end
    end
    
    pod 'ObjectMapper', '= 1.3.0'

end
