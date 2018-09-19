//
//  Rule.swift
//  Rules
//  License: MIT, included below
//

/// A `Rule` describes a logical implication, which is commonly denoted as
/// `p -> q` in mathematics, where `->` means "implies".
///
/// In this system, it is described as `LHS => RHS`, where `=>` is read as
/// "then". The whole rule is read colloquially as:
///
/// _"If the LHS is true, then the RHS declares this fact."_
///
/// The RHS (or right hand side) of a `Rule` declares a fact. The fact is an
/// `answer` for a `question`. An `Brain` is used to get the `answer` of a
/// `question`.
///
/// The LHS (or left hand side) of a `Rule` is comprised of two parts:
/// - its `priority` ranks the importance of the `Rule` relative to others.
/// - its `predicate` can be evaluated to a `Bool`, given a `Facts`.
///
/// The RHS (or right hand side) of a `Rule` is comprised of three parts:
/// - a `question`, which is the identifier for a fact.
///
/// Given a set of `Rule`s with the same RHS `question`, the `Rule` that "wins"
/// or "takes effect" or "applies" is the one with the highest `priority`
/// amongst the subset of `Rules` whose `predicate` evaluates to `true` in a
/// given `Facts`.
///
/// When a rule takes effect, the inferred fact it declared is remembered in the
/// `Facts`. The `Facts` knows which other questions were needed to determine
/// the answer to the inferred fact and uses that information to forget inferred
/// answers when they're no longer valid because the answers to those other
/// questions changed.
///
/// - note: a `Rule` is invalid if its `predicate` contains its `question`.
public struct Rule: Equatable, Codable {

    /// Higher priority `Rule`s have their `predicate` checked before `Rules`
    /// with lower `priority`.
    /// The RHS of a higher `priority` `Rule` that matches the current state of
    /// the `Facts` overrides lower-`priority` rules.
    public let priority: Int

    /// The LHS condition of the `Rule`. A `Rule`'s RHS only applies if its
    /// `predicate` matches the current state of the `Facts`.
    ///
    /// - note: The predicate can include comparison against other questions
    ///         whose values are not known in the `Facts`. The answer to
    ///         those questions will be determined recursively.
    public let predicate: Predicate

    /// The RHS `question` is the identifier which the `RHS` `answer` is
    /// associated with.
    public let question: Facts.Question

    /// The `Facts` provides this RHS `answer` as the result of a question for
    /// this `Rule`'s RHS `question` iff this `Rule` has the highest `priority`
    /// amongst all `Rule`s for that question currently matching the state of
    /// the `Facts`.
    public let answer: Facts.Answer

    /// If `nil`, the the `Rule`'s `answer` will be returned verbatim as the
    /// answer for an inferred fact.
    /// Otherwise, the answer for an inferred fact is the result of calling the
    /// associated `Brain.AssignmentFunction`.
    public let assignment: Brain.Assignment?

    public init(
        priority: Int,
        predicate: Predicate,
        question: Facts.Question,
        answer: Facts.Answer,
        assignment: Brain.Assignment?
        ) {
        self.priority = priority
        self.predicate = predicate
        self.question = question
        self.answer = answer
        self.assignment = assignment
    }
}

public extension Rule {
    static let mock = Rule.init(
        priority: 0,
        predicate: .mock,
        question: .mock,
        answer: .mock,
        assignment: nil
    )
}

public extension Array where Element == Rule {
    static let mock = [Rule.mock]
}

public enum HumanRuleParsingError: Error, Equatable {
    case humanRuleNotFound
    case prioritySeparatorNotFound
    case priorityNotFound
    case predicateAndFactNotFound
    case invalidPriority
    case implicationOperatorNotFound
    case invalidPredicate(ConversionError)
    case equalOperatorNotFound
    case invalidLine
    case factAnswerNotFound
    case factAnswerAssignmentClosingDelimiterNotFound
    case factAssignmentNotFound
    case factAnswerNotFoundAfterAssignmentDelimiter
    case factAnswerInvalidBoolValue
    case factAnswerInvalidDoubleValue
    case factAnswerInvalidIntValue
}

public typealias HumanRuleParsingResult = Rules.Result<HumanRuleParsingError, Rule>

// MARK: - Parsing textual `Rule`s

// The code from here down will not be needed on other platforms like Android
// unless you cannot use this code to convert your textual rule files to JSON.

/// This parser is not completely finished, it's not quite robust enough
public func parse(humanRule: String) -> HumanRuleParsingResult {
    // right now this parses:
    //   priority: predicate => question = answer
    // eventually it will support:
    //   priority: predicate => question = answer [assignment]
    // and value will not be assumed to be a `String`, it will be support
    // all the types in `Rule.Value`, which are `String`, `Int`, `Double`, and
    // `Bool`.
    guard !humanRule.isEmpty else {
        return .failed(.humanRuleNotFound)
    }
    let parts1 = humanRule.split(separator: ":", maxSplits: 1)
        .map(Substring.trimToString)
    guard parts1.count == 2 else {
        return .failed(.prioritySeparatorNotFound)
    }
    let priorityString = parts1[0]
    let afterPriority = parts1[1]

    guard !priorityString.isEmpty else {
        return .failed(.priorityNotFound)
    }
    guard !afterPriority.isEmpty else {
        return .failed(.predicateAndFactNotFound)
    }
    guard let priority = Int(parts1[0]) else {
        return .failed(.invalidPriority)
    }
    guard let implicationOperatorRange = afterPriority.range(of: "=>") else {
        return .failed(.implicationOperatorNotFound)
    }
    let predicateFormat = afterPriority[afterPriority.startIndex..<implicationOperatorRange.lowerBound]
        |> Substring.trimToString
    let afterImplicationOperator = afterPriority[implicationOperatorRange.upperBound..<afterPriority.endIndex]
        |> Substring.trimToString

    let factParts = afterImplicationOperator
        .split(separator: "=", maxSplits: 1)
        .map(Substring.trimToString)
    guard factParts.count == 2 else {
        return .failed(.equalOperatorNotFound)
    }
    let factQuestion = factParts[0]
    let factAnswerInput = factParts[1]

    let makeRule: (FactAnswer) -> (Predicate) -> Rule = { factAnswer in
        return { predicate in
            .init(
                priority: priority,
                predicate: predicate,
                question: .init(identifier: factQuestion),
                answer: factAnswer.answer,
                assignment: factAnswer.assignment
            )
        }
    }
    return parse(factAnswer: factAnswerInput)
        .flatMapSuccess({ factAnswer in
            convert(ns: parse(format: predicateFormat))
                .bimap(
                    HumanRuleParsingError.invalidPredicate,
                    makeRule(factAnswer)
            )
        })
}

struct FactAnswer: Equatable {
    let answer: Facts.Answer
    let assignment: Brain.Assignment?
}

func parse(factAnswer input: String) -> Rules.Result<HumanRuleParsingError, FactAnswer> {
    let trimmedInput = input |> String.trim
    switch trimmedInput.first {
    case .none:
        return .failed(.factAnswerNotFound)
    case "("?:
        let parts1 = input
            .dropFirst()
            .split(separator: ")", maxSplits: 1)
            .map(Substring.trimToString)
        guard parts1.count == 2 else {
            return .failed(.factAnswerAssignmentClosingDelimiterNotFound)
        }
        let assignment = parts1[0]
        let answer = parts1[1]
        guard !assignment.isEmpty else {
            return .failed(.factAssignmentNotFound)
        }
        guard !answer.isEmpty else {
            return .failed(.factAnswerNotFoundAfterAssignmentDelimiter)
        }
        switch (assignment, answer) {
        case ("bool", "true"):
            return .success(.init(answer: .bool(true), assignment: nil))
        case ("bool", "false"):
            return .success(.init(answer: .bool(false), assignment: nil))
        case ("bool", _):
            return .failed(.factAnswerInvalidBoolValue)
        case ("double", let answer):
            return Double(answer)
                .map { .success(.init(answer: .double($0), assignment: nil)) }
                ?? .failed(.factAnswerInvalidDoubleValue)
        case ("int", let answer):
            return Int(answer)
                .map { .success(.init(answer: .int($0), assignment: nil)) }
                ?? .failed(.factAnswerInvalidIntValue)
        case ("string", let answer):
            return .success(.init(answer: .string(answer), assignment: nil))
        case (let assignment, let answer):
            return .success(.init(answer: .string(answer), assignment: .init(identifier: assignment)))
        }
    default:
        return .success(.init(answer: .string(input), assignment: nil))
    }
}

public struct HumanRuleFileContentsParsingError: Error, Equatable {
    public let lineNumber: Int
    public let line: String
    public let error: HumanRuleParsingError

    public init(_ lineNumber: Int, _ line: String, _ error: HumanRuleParsingError) {
        self.lineNumber = lineNumber
        self.line = line
        self.error = error
    }

    public var localizedDescription: String {
        return error.localizedDescription
    }
}

public struct ParsedHumanRule: Equatable {
    public let lineNumber: Int
    public let line: String
    public let rule: Rule
}

public func parse(humanRuleFileContents content: String) -> Rules.Result<[HumanRuleFileContentsParsingError], [ParsedHumanRule]> {
    let digits: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    var rules: [ParsedHumanRule] = []
    var errors: [HumanRuleFileContentsParsingError] = []
    for case let (offset, line) in content.split(separator: "\n").enumerated() {
        let lineNumber = offset + 1
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        guard let firstChar = trimmedLine.first else {
            continue
        }
        if digits.contains(firstChar) {
            switch parse(humanRule: trimmedLine) {
            case .failed(let error):
                errors.append(.init(lineNumber, String(line), error))
            case .success(let rule):
                rules.append(.init(lineNumber: lineNumber, line: String(line), rule: rule))
            }
        } else if trimmedLine.hasPrefix("//") {
            continue
        } else {
            errors.append(.init(lineNumber, String(line), .invalidLine))
        }
    }
    return errors.isEmpty ? .success(rules) : .failed(errors)
}

//  Created by Jim Roepcke on 2018-06-24.
//  Copyright © 2018- Jim Roepcke.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//
