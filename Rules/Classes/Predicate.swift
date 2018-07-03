//
//  Predicate.swift
//  Rules
//  License: MIT, included below
//

public enum Predicate {

    public typealias EvaluationResult = Rules.Result<Predicate.EvaluationError, Predicate.Evaluation>

    public typealias Match = Set<Context.RHSKey>

    case `false`
    case `true`
    indirect case not(Predicate)
    indirect case and([Predicate])
    indirect case or([Predicate])
    indirect case comparison(lhs: Expression, op: ComparisonOperator, rhs: Expression)

    public enum Expression {
        case key(Key)
        case value(Value)
        case predicate(Predicate)
    }

    public enum ComparisonOperator {
        case isEqualTo
        case isNotEqualTo
        case isLessThan
        case isGreaterThan
        case isLessThanOrEqualTo
        case isGreaterThanOrEqualTo
    }

    public struct Key {
        public let value: Context.RHSKey
    }

    // does not include `.bool` because `.true` and `.false` are directly in `Predicate`
    public enum Value {
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
        public let keys: Set<Context.RHSKey>

        public static let `false` = Evaluation(value: false, keys: [])
        public static let `true` = Evaluation(value: true, keys: [])

        public static func invert(_ result: Evaluation) -> Evaluation {
            return .init(value: !result.value, keys: result.keys)
        }
    }

    public enum EvaluationError: Error, Equatable {
        case typeMismatch
        case predicatesAreOnlyEquatableNotComparable
        case keyEvaluationFailed(Context.AnswerError)
    }

    public func matches(in context: Context) -> Match? { // TODO: change this to return a `Rules.Result`
        let evaluation = evaluate(predicate: self, in: context)
        switch evaluation {
        case .failed:
            return nil // TODO: this should be returning the error
        case .success(let result):
            return result.keys
        }
    }

}

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

extension Context.Answer {
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

func evaluateCompound(predicates: [Predicate], in context: Context, identity: Bool) -> Predicate.EvaluationResult {
    var keys: Set<Context.RHSKey> = []
    for predicate in predicates {
        let result = evaluate(predicate: predicate, in: context)
        switch result {
        case .failed:
            return result
        case let .success(result):
            keys.formUnion(result.keys)
            if result.value == identity {
                return .success(.init(value: identity, keys: keys))
            }
        }
    }
    return .success(.init(value: !identity, keys: keys))
}

func comparePredicates(lhs: Predicate, f: (Bool, Bool) -> Bool, rhs: Predicate, in context: Context) -> Predicate.EvaluationResult {
    let lhsEvaluation = evaluate(predicate: lhs, in: context)
    switch lhsEvaluation {
    case .failed:
        return lhsEvaluation
    case .success(let lhsResult):
        let rhsEvaluation = evaluate(predicate: rhs, in: context)
        switch rhsEvaluation {
        case .failed:
            return rhsEvaluation
        case .success(let rhsResult):
            return .success(
                .init(
                    value: f(lhsResult.value, rhsResult.value),
                    keys: lhsResult.keys.union(rhsResult.keys)
                )
            )
        }
    }
}

/// only succeeds if the key evaluates to a boolean value
/// otherwise, .failed(.typeMismatch)
func comparePredicateToKey(predicate: Predicate, f: (Bool, Bool) -> Bool, key: Context.RHSKey, in context: Context) -> Predicate.EvaluationResult {
    let pResult = evaluate(predicate: predicate, in: context)
    switch pResult {
    case .failed: return pResult
    case .success(let pResult):
        let result = context[key]
        switch result {
        case .failed(let answerError):
            return .failed(.keyEvaluationFailed(answerError))
        case .success(.bool(let bool, let match)):
            return .success(
                .init(
                    value: f(pResult.value, bool),
                    keys: match.union(pResult.keys).union([key])
                )
            )
        case .success:
            return .failed(.typeMismatch)
        }
    }
}

func compareAnswers(lhs: Context.Answer, op: Predicate.ComparisonOperator, rhs: Context.Answer, keys: Set<Context.RHSKey>) -> Predicate.EvaluationResult {
    switch (lhs, rhs) {
    case let (.bool(lhsValue, lhsMatch), .bool(rhsValue, rhsMatch)):
        return op.same(lhsValue, rhsValue)
            .map { .success(.init(value: $0, keys: lhsMatch.union(rhsMatch).union(keys))) }
            ?? .failed(.predicatesAreOnlyEquatableNotComparable)
    case let (.int(lhsValue, lhsMatch), .int(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(lhsValue, rhsValue), keys: lhsMatch.union(rhsMatch).union(keys)))
    case let (.double(lhsValue, lhsMatch), .double(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(lhsValue, rhsValue), keys: lhsMatch.union(rhsMatch).union(keys)))
    case let (.string(lhsValue, lhsMatch), .string(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(lhsValue, rhsValue), keys: lhsMatch.union(rhsMatch).union(keys)))
    case let (.int(lhsValue, lhsMatch), .double(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(Double(lhsValue), rhsValue), keys: lhsMatch.union(rhsMatch).union(keys)))
    case let (.double(lhsValue, lhsMatch), .int(rhsValue, rhsMatch)):
        return .success(.init(value: op.compare(lhsValue, Double(rhsValue)), keys: lhsMatch.union(rhsMatch).union(keys)))
    default:
        return .failed(.typeMismatch)
    }
}

// only succeeds if both keys evaluate to the "same" type
// otherwise, .failed(.typeMismatch)
// if both keys evaluate to boolean values
//   only succeeds if the op is == or !=
//   otherwise .failed(.predicatesAreOnlyEquatableNotComparable)
func compareKeyToKey(lhs: Context.RHSKey, op: Predicate.ComparisonOperator, rhs: Context.RHSKey, in context: Context) -> Predicate.EvaluationResult {
    let lhsResult = context[lhs]
    switch lhsResult {
    case .failed(let answerError):
        return .failed(.keyEvaluationFailed(answerError))
    case .success(let lhsAnswer):
        let rhsResult = context[rhs]
        switch rhsResult {
        case .failed(let answerError):
            return .failed(.keyEvaluationFailed(answerError))
        case .success(let rhsAnswer):
            return compareAnswers(lhs: lhsAnswer, op: op, rhs: rhsAnswer, keys: [lhs, rhs])
        }
    }
}

// only succeeds if the `key` evaluates to the "same" type as the `value`
// otherwise, `.failed(.typeMismatch)`
// if the `key` evaluates to a `.success(.bool)`, `.failed(typeMismatch)`
func compareKeyToValue(key: Context.RHSKey, op: Predicate.ComparisonOperator, value: Predicate.Value, in context: Context) -> Predicate.EvaluationResult {
    let answerResult = context[key]
    switch answerResult {
    case .failed(let answerError):
        return .failed(.keyEvaluationFailed(answerError))
    case .success(let answer):
        return answer.asPredicateValue()
            .map { compareValueToValue(lhs: $0, op: op, rhs: value, match: answer.match.union([key])) }
            ?? .failed(.typeMismatch)
    }
}

func compareValueToValue(lhs: Predicate.Value, op: Predicate.ComparisonOperator, rhs: Predicate.Value, match: Set<Context.RHSKey>) -> Predicate.EvaluationResult {
    switch (lhs, rhs) {
    case (.int(let lhs), .int(let rhs)):
        return .success(.init(value: op.compare(lhs, rhs), keys: match))
    case (.double(let lhs), .double(let rhs)):
        return .success(.init(value: op.compare(lhs, rhs), keys: match))
    case (.string(let lhs), .string(let rhs)):
        return .success(.init(value: op.compare(lhs, rhs), keys: match))
    case (.int(let lhs), .double(let rhs)):
        return .success(.init(value: op.compare(Double(lhs), rhs), keys: match))
    case (.double(let lhs), .int(let rhs)):
        return .success(.init(value: op.compare(lhs, Double(rhs)), keys: match))
    default:
        return .failed(.typeMismatch)
    }
}

func evaluate(predicate: Predicate, in context: Context) -> Predicate.EvaluationResult {
    switch predicate {
    case .false: return .success(.false)
    case .true: return .success(.true)
    case .not(let predicate): return evaluate(predicate: predicate, in: context).bimap(Rules.id, Predicate.Evaluation.invert)
    case .and(let predicates): return evaluateCompound(predicates: predicates, in: context, identity: false)
    case .or(let predicates): return evaluateCompound(predicates: predicates, in: context, identity: true)

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
        return comparePredicates(lhs: lhs, f: ==, rhs: rhs, in: context)
    case .comparison(.predicate(let lhs), .isNotEqualTo, .predicate(let rhs)):
        return comparePredicates(lhs: lhs, f: !=, rhs: rhs, in: context)

    case .comparison(.predicate, _, .value),
         .comparison(.value, _, .predicate):
        return .failed(.typeMismatch)

    case .comparison(.predicate(let p), .isEqualTo, .key(let key)),
         .comparison(.key(let key), .isEqualTo, .predicate(let p)):
        return comparePredicateToKey(predicate: p, f: ==, key: key.value, in: context)

    case .comparison(.predicate(let p), .isNotEqualTo, .key(let key)),
         .comparison(.key(let key), .isNotEqualTo, .predicate(let p)):
        return comparePredicateToKey(predicate: p, f: !=, key: key.value, in: context)

    case .comparison(.key(let lhs), let op, .key(let rhs)):
        return compareKeyToKey(lhs: lhs.value, op: op, rhs: rhs.value, in: context)

    case .comparison(.key(let key), let op, .value(let value)):
        return compareKeyToValue(key: key.value, op: op, value: value, in: context)

    case .comparison(.value(let value), let op, .key(let key)):
        return compareKeyToValue(key: key.value, op: op.swapped, value: value, in: context)

    case .comparison(.value(let lhs), let op, .value(let rhs)):
        return compareValueToValue(lhs: lhs, op: op, rhs: rhs, match: [])
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
