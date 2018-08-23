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
  s.summary          = 'A forward-chaining inference engine rule engine'
  s.description      = <<-DESC
Rules provides a simple forward-chaining inference rule engine that is configurable at runtime.

When you provide a set of _known facts_, and a set of _rules_, _inferred facts_ 
can be determined.

For example:

- _known fact_: the sky is blue
- _rule_: if the sky is blue, then the weather is sunny
- _inferrable fact_: the weather is sunny

You you make much more complicated rules than this, which are
based on more facts, even based on inferred facts.

For example:

- _known fact_: the sky is blue
- _known fact_: the season is summer
- _rule_: if the sky is blue, then the weather is sunny
_ _rule_: if true, the beach is empty (this is a fallback rule)
- _rule_: if the weather is sunny and the season is summer, then the beach is full
- _inferred fact_: the beach is full

- _known fact_: the season is autumn
- _inferred fact_: the beach is empty

Rules can be specified using a simple textual format, and can be decoded from JSON
to load into a `Brain`.
                       DESC

  s.homepage         = 'https://github.com/JimRoepcke/Rules'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jim Roepcke' => 'jim@roepcke.com' }
  s.source           = { :git => 'https://github.com/JimRoepcke/Rules.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Rules/Sources/**/*'
  
  # s.resource_bundles = {
  #   'Rules' => ['Rules/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
