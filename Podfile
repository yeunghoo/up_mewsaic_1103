source 'https://cdn.cocoapods.org/'
platform :ios, '15.0'
project 'loop_miao.xcodeproj'

use_frameworks! :linkage => :static

target 'loop_miao' do
  pod 'InMobiSDK', '11.5.0'
end

# CI passes the app's signing profile on the command line. Pod build products
# themselves do not need provisioning profiles; the app embeds/signs the SDK.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end
