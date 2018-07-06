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
/// The RHS (or right hand side) of a `Rule` declares a fact. The fact is a
/// `value` for a `key`. An `Engine` is used to get the `value` of a `key`.
///
/// The LHS (or left hand side) of a `Rule` is comprised of two parts:
/// - its `priority` ranks the importance of the `Rule` relative to others.
/// - its `predicate` can be evaluated to a `Bool`, given a `Context`.
///
/// The RHS (or right hand side) of a `Rule` is comprised of three parts:
/// - a `key`, which is the identifier for the
///
/// Given a set of `Rule`s with the same RHS `key`, the `Rule` that "wins" or
/// "takes effect" or "applies" is the one with the highest `priority` amongst
/// the subset of `Rules` whose `predicate` evaluates to `true` in a given
/// `Context`.
///
/// When a rule takes effect, the fact it declared is cached in the `Context`.
/// The `Context` knows which other values were considered 
///
/// - note: a `Rule` is invalid if its `predicate` contains the RHS `key`.
public struct Rule {

    /// If an Assignment cannot provide a `Context.Answer`, it returns one
    /// of these error cases.
    public enum FiringError: Swift.Error, Equatable {
        /// An unexpected error occurred.
        /// - parameter debugDescription: use for debug logging.
        case failed(debugDescription: String)
        /// The format of the RHS value was somehow incompatable with the `assignment`.
        /// - parameter debugDescription: use for debug logging.
        /// - parameter value: The RHS `value` of the `Rule` the `assignment` could not process.
        case invalidRHSValue(debugDescription: String, value: Predicate.Value)
    }

    public typealias FiringResult = Rules.Result<FiringError, Context.Answer>

    /// TODO: this is going to change to a `String` which the `Engine` uses to look up
    /// an `Assignment` function by name. This will make it easy to make the
    /// `Rule` type `Codable` for conversion to/from JSON.
    public typealias Assignment = (Rule, Context, Predicate.Match) -> FiringResult

    /// Higher priority `Rule`s have their `predicate` checked before `Rules`
    /// with lower `priority`.
    /// The RHS of a higher `priority` `Rule` that matches the current state of
    /// the `Context` overrides lower-`priority` rules.
    public let priority: Int

    /// The LHS condition of the `Rule`. A `Rule`'s RHS only applies if its
    /// `predicate` matches the current state of the `Context`.
    ///
    /// - note: The predicate can include comparison against other keys whose
    ///         values are not stored in the `Context`. The value of those keys
    ///         will be looked up using the `Context` recursively.
    public let predicate: Predicate

    /// The RHS `key` is the identifier which the `RHS` `value` is associated with.
    public let key: Context.RHSKey // which is `String`

    /// Enumerates the possible return `value`s associated with a `Rule`.
    public enum Value: Equatable {
        case bool(Bool)
        case double(Double)
        case int(Int)
        case string(String)
    }

    /// The `Context` provides this RHS `value` as the result of a lookup of
    /// this `Rule`'s RHS `key` iff this `Rule` has the highest priority amongst
    /// all `Rule`s currently matching the state of the `Context`.
    public let value: Context.RHSValue // currently `String`, will change to `Value`

    /// the standard/default assignment will just return the `value` as is.
    public let assignment: Assignment // will change to `String`

    /// This method is going to move into `Context` when `assignment`
    /// is changed from a function to a `String`
    func fire(in context: Context, match: Predicate.Match) -> FiringResult {
        return assignment(self, context, match)
    }
}

public enum RuleParsingError: Error, Equatable {
    case prioritySeparatorNotFound
    case invalidPriority
    case implicationOperatorNotFound
    case invalidPredicate(ConversionError)
    case equalOperatorNotFound
}

typealias RuleParsingResult = Rules.Result<RuleParsingError, Rule>

/// This parser is not completely finished, it's not quite robust enough
func parse(humanRule: String) -> RuleParsingResult {
    // right now this parses:
    //   priority: predicate => key = value
    // eventually it will support:
    //   priority: predicate => key = value [assignment]
    // and value will not be assumed to be a `String`, it will be support
    // all the types in `Rule.Value`, which are `String`, `Int`, `Double`, and
    // `Bool`.
    let trim = Rules.flip(String.trimmingCharacters)(.whitespacesAndNewlines)
    let parts1 = humanRule.split(separator: ":", maxSplits: 1).map(String.init).map(trim)
    guard parts1.count == 2 else {
        return .failed(.prioritySeparatorNotFound)
    }
    guard let priority = Int(trim(parts1[0])) else {
        return .failed(.invalidPriority)
    }
    let afterPriority = parts1[1]
    guard let implicationOperatorRange = afterPriority.range(of: "=>") else {
        return .failed(.implicationOperatorNotFound)
    }
    let predicateFormat = afterPriority[afterPriority.startIndex..<implicationOperatorRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)

    let afterImplicationOperator = afterPriority[implicationOperatorRange.upperBound..<afterPriority.endIndex].trimmingCharacters(in: .whitespacesAndNewlines)

    let rhsParts = afterImplicationOperator.split(separator: "=", maxSplits: 1).map(String.init).map(trim)
    guard rhsParts.count == 2 else {
        return .failed(.equalOperatorNotFound)
    }
    let key = rhsParts[0]

    // for now, leave the assignment out of the textual rule format
    let valueAndAssignment = rhsParts[1]
    let value = valueAndAssignment
    let predicateResult = convert(ns: parse(format: predicateFormat))
    switch predicateResult {
    case .failed(let error):
        return .failed(.invalidPredicate(error))
    case .success(let predicate):
        return .success(
            Rule(
                priority: priority,
                predicate: predicate,
                key: key,
                value: value,
                assignment: { rule, _, match in .success(.string(rule.value, match: match)) }
            )
        )
    }
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
