# Rules

[![Version](https://img.shields.io/cocoapods/v/Rules.svg?style=flat)](https://cocoapods.org/pods/Rules)
[![License](https://img.shields.io/cocoapods/l/Rules.svg?style=flat)](https://cocoapods.org/pods/Rules)
[![Platform](https://img.shields.io/cocoapods/p/Rules.svg?style=flat)](https://cocoapods.org/pods/Rules)

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
- _rule_: if true, the beach is empty (this is a fallback rule)
- _rule_: if the weather is sunny and the season is summer, then the beach is full
- _inferred fact_: the beach is full

- _known fact_: the season is autumn
- _inferred fact_: the beach is empty

Rules can be specified using a simple textual format, and can be decoded from JSON
to load into a `Brain`.

This repo also contains a TextRulesToJSON command-line program for macOS that can convert a text file with human-readable rules to JSON. As the `Rule` type in Rules conforms to Swift's `Decodable` protocol, this makes it easy to import rules into an application. TextRulesToJSON can also lint the rules to help ensure they are valid before they are converted to JSON.

## Example

The Example project only exists for unit tests. To run them, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Xcode 10.2
- Swift 5.0

## Installation

Rules is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Rules'
```

Rules is also available as a Swift Package. See the Rules/Package.swift file for more information.

## Author

Jim Roepcke, jim@roepcke.com

## License

Rules is available under the MIT license. See the LICENSE file for more info.
