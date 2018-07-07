//
//  Predicate.swift
//  Rules
//  License: MIT, included below
//

public enum Predicate: Equatable {

    public typealias EvaluationResult = Rules.Result<Predicate.EvaluationError, Predicate.Evaluation>

    case `false`
    case `true`
    indirect case not(Predicate)
    indirect case and([Predicate])
    indirect case or([Predicate])
    indirect case comparison(lhs: Expression, op: ComparisonOperator, rhs: Expression)

    public enum Expression: Equatable {
        case question(Facts.Question)
        case value(Value)
        case predicate(Predicate)
    }

    public enum ComparisonOperator: String, Equatable, Codable {
        case isEqualTo
        case isNotEqualTo
        case isLessThan
        case isGreaterThan
        case isLessThanOrEqualTo
        case isGreaterThanOrEqualTo
    }

    // does not include `.bool` because `.true` and `.false` are directly in `Predicate`
    public enum Value: Equatable {
        case int(Int)
        case double(Double)
        case string(String)
    }

    /// `size` helps break ties between multiple candidate rules with the same
    /// priority if this predicate is a conjunction, it is the number of
    /// operands in the conjunction.
    /// otherwise, it is the largest number of conjunctions amongst its
    /// disjunctive operands.
    public var size: Int {
        switch self {
        case .false: return 0
        case .true: return 0
        case .not(let predicate): return predicate.size
        case .and(let predicates): return predicates.count
        case .or(let predicates): return predicates.map { $0.size }.max() ?? 0
        }
    }

    public struct Evaluation: Equatable {
        public let value: Bool
        public let dependencies: Set<Facts.Question>

        public static let `false` = Evaluation(value: false, dependencies: [])
        public static let `true` = Evaluation(value: true, dependencies: [])

        public static func invert(_ result: Evaluation) -> Evaluation {
            return .init(value: !result.value, dependencies: result.dependencies)
        }
    }

    public enum EvaluationError: Error, Equatable {
        case typeMismatch
        case predicatesAreOnlyEquatableNotComparable
        case questionEvaluationFailed(Facts.AnswerError)
    }

    public func matches(given facts: Facts) -> EvaluationResult {
        return evaluate(predicate: self, given: facts)
    }

}

// MARK: - Predicate Serialization using Codable

extension Predicate.Expression: Codable {
    enum CodingKeys: String, CodingKey {
        case question
        case value
        case predicate
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.question) {
            self = .question(try container.decode(Facts.Question.self, forKey: .question))
        } else if container.contains(.value) {
            self = .value(try container.decode(Predicate.Value.self, forKey: .value))
        } else if container.contains(.predicate) {
            self = .predicate(try container.decode(Predicate.self, forKey: .predicate))
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "none of the following keys were found in the JSON object: 'question', 'value' 'predicate'"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .question(let question):
            try container.encode(question.identifier, forKey: .question)
        case .value(let value):
            try container.encode(value, forKey: .value)
        case .predicate(let predicate):
            try container.encode(predicate, forKey: .predicate)
        }
    }
}

extension Predicate.Value: Codable {
    enum CodingKeys: String, CodingKey {
        case int
        case double
        case string
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.int) {
            self = .int(try container.decode(Int.self, forKey: .int))
        } else if container.contains(.double) {
            self = .double(try container.decode(Double.self, forKey: .double))
        } else if container.contains(.string) {
            self = .string(try container.decode(String.self, forKey: .string))
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "no int, double or string key"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .int(let value):
            try container.encode(value, forKey: .int)
        case .double(let value):
            try container.encode(value, forKey: .double)
        case .string(let value):
            try container.encode(value, forKey: .string)
        }
    }
}

extension Predicate: Codable {
    enum PredicateType: String, Equatable, Codable {
        case `false`
        case `true`
        case not
        case and
        case or
        case comparison
    }
    enum CodingKeys: String, CodingKey {
        case type
        case operand
        case operands
        case lhs
        case op
        case rhs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PredicateType.self, forKey: .type)
        switch type {
        case .false:
            self = .false
        case .true:
            self = .true
        case .not:
            let inverting = try container.decode(Predicate.self, forKey: .operand)
            self = .not(inverting)
        case .and:
            let operands = try container.decode([Predicate].self, forKey: .operands)
            self = .and(operands)
        case .or:
            let operands = try container.decode([Predicate].self, forKey: .operands)
            self = .or(operands)
        case .comparison:
            let lhs = try container.decode(Expression.self, forKey: .lhs)
            let op = try container.decode(Predicate.ComparisonOperator.self, forKey: .op)
            let rhs = try container.decode(Expression.self, forKey: .lhs)
            self = .comparison(lhs: lhs, op: op, rhs: rhs)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .false:
            try container.encode(PredicateType.false, forKey: .type)
        case .true:
            try container.encode(PredicateType.true, forKey: .type)
        case .not(let predicate):
            try container.encode(PredicateType.not, forKey: .type)
            try container.encode(predicate, forKey: .operand)
        case .and(let predicates):
            try container.encode(PredicateType.and, forKey: .type)
            try container.encode(predicates, forKey: .operands)
        case .or(let predicates):
            try container.encode(PredicateType.or, forKey: .type)
            try container.encode(predicates, forKey: .operands)
        case .comparison(let lhs, let op, let rhs):
            try container.encode(PredicateType.comparison, forKey: .type)
            try container.encode(lhs, forKey: .lhs)
            try container.encode(op, forKey: .op)
            try container.encode(rhs, forKey: .rhs)
        }
    }
}

// MARK: - Predicate Evaluation

extension Predicate.ComparisonOperator {

    var swapped: Predicate.ComparisonOperator {
        switch self {
        case .isEqualTo, .isNotEqualTo: return self
        case .isLessThan: return .isGreaterThan
        case .isGreaterThan: return .isLessThan
        case .isLessThanOrEqualTo: return .isGreaterThanOrEqualTo
        case .isGreaterThanOrEqualTo: return .isLessThanOrEqualTo
        }
    }

    func compare<A: Comparable>(_ lhs: A, _ rhs: A) -> Bool {
        switch self {
        case .isEqualTo: return lhs == rhs
        case .isNotEqualTo: return lhs != rhs
        case .isLessThan: return lhs < rhs
        case .isGreaterThan: return lhs > rhs
        case .isLessThanOrEqualTo: return lhs <= rhs
        case .isGreaterThanOrEqualTo: return lhs >= rhs
        }
    }

    func same(_ lhs: Bool, _ rhs: Bool) -> Bool? {
        switch self {
        case .isEqualTo: return lhs == rhs
        case .isNotEqualTo: return lhs != rhs
        default: return nil
        }
    }
}

extension Facts.AnswerWithDependencies {
    /// returns `nil` for `.bool`, as that does not exist in `Predicate.Value`. Otherwise, the corresponding value.
    func asPredicateValue() -> Predicate.Value? {
        switch self {
        case .bool: return nil
        case let .double(it, _): return .double(it)
        case let .int(it, _): return .int(it)
        case let .string(it, _): return .string(it)

        }
    }
}

/// Evaluates the sub-`Predicate`s of compound `Predicate`s of types: `.and`, `.or`.
/// - parameters:
///   - predicates: the sub-`Predicate`s associated with the compound `Predicate` being evaluated.
///   - facts: the `Facts` to look up `questions`s from.
///   - identity: the multiplicitive identity (`false`) for `.and`, or the additive identity `true` for `.or`.
func evaluateCompound(predicates: [Predicate], given facts: Facts, identity: Bool) -> Predicate.EvaluationResult {
    var dependencies: Set<Facts.Question> = []
    for predicate in predicates {
        let result = evaluate(predicate: predicate, given: facts)
        switch result {
        case .failed:
            return result
        case let .success(result):
            dependencies.formUnion(result.dependencies)
            if result.value == identity {
                return .success(.init(value: identity, dependencies: dependencies))
            }
        }
    }
    return .success(.init(value: !identity, dependencies: dependencies))
}

func comparePredicates(lhs: Predicate, f: (Bool, Bool) -> Bool, rhs: Predicate, given facts: Facts) -> Predicate.EvaluationResult {
    let lhsEvaluation = evaluate(predicate: lhs, given: facts)
    switch lhsEvaluation {
    case .failed:
        return lhsEvaluation
    case .success(let lhsResult):
        let rhsEvaluation = evaluate(predicate: rhs, given: facts)
        switch rhsEvaluation {
        case .failed:
            return rhsEvaluation
        case .success(let rhsResult):
            return .success(
                .init(
                    value: f(lhsResult.value, rhsResult.value),
                    dependencies: lhsResult.dependencies.union(rhsResult.dependencies)
                )
            )
        }
    }
}

/// only succeeds if the question evaluates to a boolean answer
/// otherwise, .failed(.typeMismatch)
func comparePredicateToQuestion(predicate: Predicate, f: (Bool, Bool) -> Bool, question: Facts.Question, given facts: Facts) -> Predicate.EvaluationResult {
    let predicateEvaluationResult = evaluate(predicate: predicate, given: facts)
    guard case let .success(predicateEvaluation) = predicateEvaluationResult else {
        return predicateEvaluationResult
    }
    let result = facts[question]
    switch result {
    case .failed(let answerError):
        return .failed(.questionEvaluationFailed(answerError))
    case .success(.bool(let questionAnswerValue, let questionDependencies)):
        let evaluationValue = f(predicateEvaluation.value, questionAnswerValue)
        let evaluationDependencies = questionDependencies
            .union(predicateEvaluation.dependencies)
            .union([question])
        return .success(.init(value: evaluationValue, dependencies: evaluationDependencies))
    case .success:
        return .failed(.typeMismatch)
    }
}

func compareAnswers(lhs: Facts.AnswerWithDependencies, op: Predicate.ComparisonOperator, rhs: Facts.AnswerWithDependencies, dependencies: Set<Facts.Question>) -> Predicate.EvaluationResult {
    switch (lhs, rhs) {
    case let (.bool(lhsValue, lhsMatch), .bool(rhsValue, rhsMatch)):
        return op.same(lhsValue, rhsValue)
            .map { .success(.init(value: $0, dependencies: lhsMatch.union(rhsMatch).union(dependencies))) }
            ?? .failed(.predicatesAreOnlyEquatableNotComparable)
    case let (.int(lhsValue, lhsMatch), .int(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(lhsValue, rhsValue), dependencies: lhsMatch.union(rhsMatch).union(dependencies)))
    case let (.double(lhsValue, lhsMatch), .double(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(lhsValue, rhsValue), dependencies: lhsMatch.union(rhsMatch).union(dependencies)))
    case let (.string(lhsValue, lhsMatch), .string(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(lhsValue, rhsValue), dependencies: lhsMatch.union(rhsMatch).union(dependencies)))
    case let (.int(lhsValue, lhsMatch), .double(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(Double(lhsValue), rhsValue), dependencies: lhsMatch.union(rhsMatch).union(dependencies)))
    case let (.double(lhsValue, lhsMatch), .int(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(lhsValue, Double(rhsValue)), dependencies: lhsMatch.union(rhsMatch).union(dependencies)))
    default:
        return .failed(.typeMismatch)
    }
}

// only succeeds if both questions evaluate to the "same" type
// otherwise, .failed(.typeMismatch)
// if both questions evaluate to boolean values
//   only succeeds if the op is == or !=
//   otherwise .failed(.predicatesAreOnlyEquatableNotComparable)
func compareQuestionToQuestion(lhs: Facts.Question, op: Predicate.ComparisonOperator, rhs: Facts.Question, given facts: Facts) -> Predicate.EvaluationResult {
    let lhsResult = facts[lhs]
    switch lhsResult {
    case .failed(let answerError):
        return .failed(.questionEvaluationFailed(answerError))
    case .success(let lhsAnswer):
        let rhsResult = facts[rhs]
        switch rhsResult {
        case .failed(let answerError):
            return .failed(.questionEvaluationFailed(answerError))
        case .success(let rhsAnswer):
            return compareAnswers(lhs: lhsAnswer, op: op, rhs: rhsAnswer, dependencies: [lhs, rhs])
        }
    }
}

// only succeeds if the `question` evaluates to the "same" type as the `value`
// otherwise, `.failed(.typeMismatch)`
// if the `question` evaluates to a `.success(.bool)`, `.failed(typeMismatch)`
func compareQuestionToValue(question: Facts.Question, op: Predicate.ComparisonOperator, value: Predicate.Value, given facts: Facts) -> Predicate.EvaluationResult {
    let answerResult = facts[question]
    switch answerResult {
    case .failed(let answerError):
        return .failed(.questionEvaluationFailed(answerError))
    case .success(let answer):
        return answer.asPredicateValue()
            .map { compareValueToValue(lhs: $0, op: op, rhs: value, dependencies: answer.dependencies.union([question])) }
            ?? .failed(.typeMismatch)
    }
}

func compareValueToValue(lhs: Predicate.Value, op: Predicate.ComparisonOperator, rhs: Predicate.Value, dependencies: Set<Facts.Question>) -> Predicate.EvaluationResult {
    switch (lhs, rhs) {
    case (.int(let lhs), .int(let rhs)):
        return .success(.init(value: op.compare(lhs, rhs), dependencies: dependencies))
    case (.double(let lhs), .double(let rhs)):
        return .success(.init(value: op.compare(lhs, rhs), dependencies: dependencies))
    case (.string(let lhs), .string(let rhs)):
        return .success(.init(value: op.compare(lhs, rhs), dependencies: dependencies))
    case (.int(let lhs), .double(let rhs)):
        return .success(.init(value: op.compare(Double(lhs), rhs), dependencies: dependencies))
    case (.double(let lhs), .int(let rhs)):
        return .success(.init(value: op.compare(lhs, Double(rhs)), dependencies: dependencies))
    default:
        return .failed(.typeMismatch)
    }
}

func evaluate(predicate: Predicate, given facts: Facts) -> Predicate.EvaluationResult {
    switch predicate {
    case .false: return .success(.false)
    case .true: return .success(.true)
    case .not(let predicate): return evaluate(predicate: predicate, given: facts).bimap(Rules.id, Predicate.Evaluation.invert)
    case .and(let predicates): return evaluateCompound(predicates: predicates, given: facts, identity: false)
    case .or(let predicates): return evaluateCompound(predicates: predicates, given: facts, identity: true)

    case .comparison(.predicate, .isLessThan, _),
         .comparison(.predicate, .isGreaterThan, _),
         .comparison(.predicate, .isGreaterThanOrEqualTo, _),
         .comparison(.predicate, .isLessThanOrEqualTo, _),
         .comparison(_, .isLessThan, .predicate),
         .comparison(_, .isGreaterThan, .predicate),
         .comparison(_, .isGreaterThanOrEqualTo, .predicate),
         .comparison(_, .isLessThanOrEqualTo, .predicate):
        return .failed(.predicatesAreOnlyEquatableNotComparable)

    case .comparison(.predicate(let lhs), .isEqualTo, .predicate(let rhs)):
        return comparePredicates(lhs: lhs, f: ==, rhs: rhs, given: facts)
    case .comparison(.predicate(let lhs), .isNotEqualTo, .predicate(let rhs)):
        return comparePredicates(lhs: lhs, f: !=, rhs: rhs, given: facts)

    case .comparison(.predicate, _, .value),
         .comparison(.value, _, .predicate):
        return .failed(.typeMismatch)

    case .comparison(.predicate(let p), .isEqualTo, .question(let question)),
         .comparison(.question(let question), .isEqualTo, .predicate(let p)):
        return comparePredicateToQuestion(predicate: p, f: ==, question: question, given: facts)

    case .comparison(.predicate(let p), .isNotEqualTo, .question(let question)),
         .comparison(.question(let question), .isNotEqualTo, .predicate(let p)):
        return comparePredicateToQuestion(predicate: p, f: !=, question: question, given: facts)

    case .comparison(.question(let lhs), let op, .question(let rhs)):
        return compareQuestionToQuestion(lhs: lhs, op: op, rhs: rhs, given: facts)

    case .comparison(.question(let question), let op, .value(let value)):
        return compareQuestionToValue(question: question, op: op, value: value, given: facts)

    case .comparison(.value(let value), let op, .question(let question)):
        return compareQuestionToValue(question: question, op: op.swapped, value: value, given: facts)

    case .comparison(.value(let lhs), let op, .value(let rhs)):
        return compareValueToValue(lhs: lhs, op: op, rhs: rhs, dependencies: [])
    }
}

public enum ConversionError: Error, Equatable {
    case compoundHasNoSubpredicates
    case inputWasNotRecognized
    case unsupportedOperator
    case unsupportedExpression
    case unsupportedConstantValue
}

public typealias ExpressionConversionResult = Rules.Result<ConversionError, Predicate.Expression>
public typealias PredicateConversionResult = Rules.Result<ConversionError, Predicate>

// MARK: - Parsing textually-formatted predicates into `Predicate` via `NSPredicate`.

// The code from here down will not be needed on other platforms like Android
// unless you cannot use this code to convert your textual rule files to JSON.

import Foundation

/// Convert a predicate `String` into an `NSPredicate`.
public func parse(format rawFormat: String) -> NSPredicate {
    let format = cleaned(format: rawFormat)
    // TODO: catch NSException if this fails
    return NSPredicate(format: format, argumentArray: nil)
}

/// NSPredicate cannot parse "true" or "false", it must be "TRUEPREDICATE" or
/// "FALSEPREDICATE". It can parse true and false inside comparisons like
/// "someQuestion == true" though. So, this deals with that issue before handing
/// the predicate format string to the `NSPredicate` initializer.
func cleaned(format rawFormat: String) -> String {
    switch rawFormat.trimmingCharacters(in: .whitespacesAndNewlines) {
    case let trimmed where trimmed.lowercased() == "true": return "TRUEPREDICATE"
    case let trimmed where trimmed.lowercased() == "false": return "FALSEPREDICATE"
    case let result: return result
    }
}

/// The textual rule file format will have the predicate parsed using
/// `NSPredicate`'s predicate parser. That is then converted to `Predicate`.
/// This frees us from having to write a predicate parser of our own.
public func convert(ns: NSPredicate) -> PredicateConversionResult {
    switch ns {
    case let compound as NSCompoundPredicate:
        guard let subpredicates = compound.subpredicates as? [NSPredicate], !subpredicates.isEmpty else {
            return .failed(.compoundHasNoSubpredicates)
        }
        switch compound.compoundPredicateType {
        case .not:
            return convert(ns: subpredicates[0]).bimap(Rules.id, Predicate.not)
        case .and:
            let subpredicateConversions = subpredicates.map(convert(ns:))
            if let failed = subpredicateConversions.first(where: { $0.value == nil }) {
                return failed
            }
            let convertedSubpredicates = subpredicateConversions.compactMap { $0.value }
            return .success(.and(convertedSubpredicates))
        case .or:
            let subpredicateConversions = subpredicates.map(convert(ns:))
            if let failed = subpredicateConversions.first(where: { $0.value == nil }) {
                return failed
            }
            let convertedSubpredicates = subpredicateConversions.compactMap { $0.value }
            return .success(.or(convertedSubpredicates))
        }
    case let comparison as NSComparisonPredicate:
        guard let op = convert(operatorType: comparison.predicateOperatorType) else {
            return .failed(.unsupportedOperator)
        }
        let lhsResult = convert(expr: comparison.leftExpression)
        switch lhsResult {
        case .failed(let error): return .failed(error)
        case .success(let lhs):
            let rhsResult = convert(expr: comparison.rightExpression)
            switch rhsResult {
            case .failed(let error): return .failed(error)
            case .success(let rhs):
                return .success(.comparison(lhs: lhs, op: op, rhs: rhs))
            }
        }
    case let unknown where unknown.predicateFormat == "TRUEPREDICATE":
        return .success(.true)
    case let unknown where unknown.predicateFormat == "FALSEPREDICATE":
        return .success(.false)
    default:
        return .failed(.inputWasNotRecognized)
    }
}

public func convert(operatorType: NSComparisonPredicate.Operator) -> Predicate.ComparisonOperator? {
    switch operatorType {
    case .lessThan: return .isLessThan
    case .lessThanOrEqualTo: return .isLessThanOrEqualTo
    case .greaterThan: return .isGreaterThan
    case .greaterThanOrEqualTo: return .isGreaterThanOrEqualTo
    case .equalTo: return .isEqualTo
    case .notEqualTo: return .isNotEqualTo
    case .matches,
         .like,
         .beginsWith,
         .endsWith,
         .in,
         .customSelector,
         .contains,
         .between: return nil // unsupported
    }
}

public func convert(expr: NSExpression) -> ExpressionConversionResult {
    switch expr.expressionType {
    case .constantValue:
        switch expr.constantValue {
        case let s as String:
            return .success(.value(.string(s)))
        case let num as NSNumber:
            let type: CFNumberType = CFNumberGetType(num)
            switch type {
            case .sInt8Type,
                 .sInt16Type,
                 .sInt32Type,
                 .sInt64Type,
                 .nsIntegerType,
                 .shortType,
                 .intType,
                 .longType,
                 .longLongType,
                 .cfIndexType:
                return .success(.value(.int(num.intValue)))
            case .float32Type,
                 .float64Type,
                 .floatType,
                 .doubleType,
                 .cgFloatType:
                return .success(.value(.double(num.doubleValue)))
            case .charType:
                return .success(.predicate(num.boolValue ? .true : .false))
            }
        default:
            return .failed(.unsupportedConstantValue)
        }
    case .keyPath:
        return .success(.question(.init(identifier: expr.keyPath)))
    case .evaluatedObject,
         .variable,
         .function,
         .unionSet,
         .intersectSet,
         .minusSet,
         .subquery,
         .aggregate,
         .anyKey,
         .block,
         .conditional:
        return .failed(.unsupportedExpression)
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
