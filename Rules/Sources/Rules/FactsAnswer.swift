//
//  FactsAnswer.swift
//  Rules
//  License: MIT, included below
//

extension Facts {

    /// Associates an answer with the questions that answer depended on.
    public struct AnswerWithDependencies: Equatable {
        public let answer: Answer
        public let dependencies: Facts.Dependencies
        public let ambiguousRules: [[Rule]]
    }

    public typealias AnswerWithDependenciesResult = Rules.Result<AnswerError, AnswerWithDependencies>

    public typealias AnswerResult = Rules.Result<AnswerError, Answer>

    /// If an `Answer` cannot be provided for a question, an `AnswerError` is
    /// provided instead.
    public enum AnswerError: Swift.Error, Equatable {
        indirect case candidateEvaluationFailed(Predicate.EvaluationError)
        case noRuleFound(question: Question)
        case ambiguous(question: Question)
        case assignmentFailed(Brain.AssignmentError)
        case answerTypeDoesNotMatchAskType(Answer)
    }

    /// A `value` provided to `Facts` either by:
    /// - the client of `Facts` as the answer to a question with a known fact
    /// - the receiver's `Brain` as the answer to a question with an inferred fact.
    public enum Answer {
        case bool(Bool)
        case double(Double)
        case int(Int)
        case string(String)
        case comparable(ComparableAnswer)
        case equatable(EquatableAnswer)
    }
}

public extension Facts.AnswerWithDependencies {
    static let mock = Facts.AnswerWithDependencies(
        answer: .mock,
        dependencies: [.mock],
        ambiguousRules: []
    )
}

public extension Facts.AnswerError {
    static let mock = Facts.AnswerError.noRuleFound(question: .mock)
}

public extension Facts.Answer {
    static let mock = Facts.Answer.string("mock")
}

extension Facts.Answer: Equatable {

    public static func == (lhs: Facts.Answer, rhs: Facts.Answer) -> Bool {
        switch (lhs, rhs) {
        case (.bool(let l), .bool(let r)): return l == r
        case (.bool, _): return false
        case (.double(let l), .double(let r)): return l == r
        case (.double, _): return false
        case (.int(let l), .int(let r)): return l == r
        case (.int, _): return false
        case (.string(let l), .string(let r)): return l == r
        case (.string, _): return false
        case (.comparable(let l), .comparable(let r)): return l.isEqualTo(comparableAnswer: r).value ?? false
        case (.comparable, _): return false
        case (.equatable(let l), .equatable(let r)): return l.isEqualTo(equatableAnswer: r).value ?? false
        case (.equatable, _): return false
        }
    }
}

extension Facts.Answer: ExpressibleByBooleanLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {

    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }

    public init(floatLiteral value: Double) {
        self = .double(value)
    }

    public init(integerLiteral value: Int) {
        self = .int(value)
    }

    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Facts.Answer {
    init(answerWithDependendOnQuestions: Facts.AnswerWithDependencies) {
        self = answerWithDependendOnQuestions.answer
    }

    func asAnswerWithDependencies(_ dependencies: Facts.Dependencies = [], ambiguousRules: [[Rule]]) -> Facts.AnswerWithDependencies {
        return .init(answer: self, dependencies: dependencies, ambiguousRules: ambiguousRules)
    }
}

extension Facts.Answer {

    public typealias ComparisonResult = Rules.Result<Predicate.EvaluationError, Bool>

    public func isEqual(to other: Facts.Answer) -> ComparisonResult {
        switch (self, other) {
        case (.bool(let it), .bool(let other)): return .success(it == other)
        case (.double(let it), .double(let other)): return .success(it == other)
        case (.int(let it), .int(let other)): return .success(it == other)
        case (.string(let it), .string(let other)): return .success(it == other)
        case (.comparable(let it), .comparable(let other)): return it.isEqualTo(comparableAnswer: other)
        case (.equatable(let it), .equatable(let other)): return it.isEqualTo(equatableAnswer: other)
        case (.bool, _), (.double, _), (.int, _), (.string, _), (.comparable, _), (.equatable, _): return .failed(.typeMismatch)
        }
    }

    public func isNotEqual(to other: Facts.Answer) -> ComparisonResult {
        return isEqual(to: other).mapSuccess(!)
    }

    public func isLess(than other: Facts.Answer) -> ComparisonResult {
        switch (self, other) {
        case (.double(let it), .double(let other)): return .success(it < other)
        case (.int(let it), .int(let other)): return .success(it < other)
        case (.string(let it), .string(let other)): return .success(it < other)
        case (.comparable(let it), .comparable(let other)): return it.isLessThan(comparableAnswer: other)
        case (.bool, _), (.double, _), (.int, _), (.string, _), (.comparable, _), (.equatable, _): return .failed(.typeMismatch)
        }
    }

    public func isLessThanOrEqual(to other: Facts.Answer) -> ComparisonResult {
        return isLess(than: other).flatMapSuccess { lt in
            if lt { return .success(true) }
            else { return isEqual(to: other) }
        }
    }

    public func isGreater(than other: Facts.Answer) -> ComparisonResult {
        return isLessThanOrEqual(to: other).mapSuccess(!)
    }

    public func isGreaterThanOrEqual(to other: Facts.Answer) -> ComparisonResult {
        return isLess(than: other).mapSuccess(!)
    }

}

public protocol EquatableAnswer {
    func isEqualTo(equatableAnswer: EquatableAnswer) -> Facts.Answer.ComparisonResult
    func encodeEquatableAnswer(to encoder: Encoder, container: inout UnkeyedEncodingContainer) throws
    static func decodeEquatableAnswer(from decoder: Decoder, container: inout UnkeyedDecodingContainer) throws -> EquatableAnswer
    static var equatableAnswerTypeName: String { get }
}

public protocol ComparableAnswer {
    func isEqualTo(comparableAnswer: ComparableAnswer) -> Facts.Answer.ComparisonResult
    func isLessThan(comparableAnswer: ComparableAnswer) -> Facts.Answer.ComparisonResult
    func encodeComparableAnswer(to encoder: Encoder, container: inout UnkeyedEncodingContainer) throws
    static func decodeComparableAnswer(from decoder: Decoder, container: inout UnkeyedDecodingContainer) throws -> ComparableAnswer
    static var comparableAnswerTypeName: String { get }
}

//  Created by Jim Roepcke on 2018-10-18.
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
