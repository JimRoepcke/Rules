#
# Be sure to run `pod lib lint Rules.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Rules'
  s.version          = '0.1.0'
  s.summary          = 'A basic but still powerful rule engine'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A basic but still powerful rule engine.

Rules can be added at runtime, and generated programatically.
                       DESC

  s.homepage         = 'https://github.com/JimRoepcke/Rules'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jim Roepcke' => 'jim@roepcke.com' }
  s.source           = { :git => 'https://github.com/JimRoepcke/Rules.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.3'

  s.source_files = 'Rules/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Rules' => ['Rules/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
