# Rules

[![CI Status](https://img.shields.io/travis/Jim Roepcke/Rules.svg?style=flat)](https://travis-ci.org/Jim Roepcke/Rules)
[![Version](https://img.shields.io/cocoapods/v/Rules.svg?style=flat)](https://cocoapods.org/pods/Rules)
[![License](https://img.shields.io/cocoapods/l/Rules.svg?style=flat)](https://cocoapods.org/pods/Rules)
[![Platform](https://img.shields.io/cocoapods/p/Rules.svg?style=flat)](https://cocoapods.org/pods/Rules)

Rules is a pod/package that provides a simple rule engine.

Also found in this repo is a TextRulesToJSON command-line program that converts a text file with human-readable rules to JSON which can be easily imported into an application, as the `Rule` type in Rules conforms to Swift's `Decodable` protocol. This program can also lint the rules to help ensure they are valid before they are converted to JSON.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Xcode 9.4
- Swift 4.1

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
