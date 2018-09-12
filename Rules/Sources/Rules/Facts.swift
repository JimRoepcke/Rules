//
//  Facts.swift
//  Rules
//  License: MIT, included below
//

/// A mutable collection of answers to questions, both known and inferred.
///
/// **Known facts** are provided directly by the client of the `Facts`. Use
/// the `know(answer:forQuestion:)` method to create a known fact.
///
/// **Inferred facts** are provided by an `Brain` configured with `Rule`s.
/// Use the `Brain.add(rule:)` method to configure the `Brain` provided
/// in the `Facts` initializer.
///
/// If you need an answer to a question, use the `ask(question:) method`.
/// It replies with a `AnswerResult` containing either:
/// - `.success(Facts.Answer)`, or
/// - `.failed(Facts.AnswerError)`.
///
/// The `Facts` remembers (caches) all inferred answers it learns about via
/// asked questions. It knows which other questions, known and inferred, that
/// were considered when producing the inferred answer, and automatically
/// invalidates its memory (cache) when dependencies change.
public class Facts {

    /// Generates inferred facts via `Rule`s.
    public let brain: Brain

    public init(brain: Brain) {
        self.brain = brain
        self.known = [:]
        self.inferred = [:]
        self.dependencies = [:]
    }

    /// This is basically a `String`, but it's more type-safe.
    public struct Question: Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible, CustomDebugStringConvertible {
        public let identifier: String

        public typealias StringLiteralType = String

        public init(stringLiteral: String) {
            self.identifier = stringLiteral
        }

        public init(identifier: String) {
            self.identifier = identifier
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.identifier = try container.decode(String.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(identifier)
        }

        public var description: String { return identifier }
        public var debugDescription: String { return identifier }
    }

    /// A `value` provided to `Facts` either by:
    /// - the client of `Facts` as the answer to a question with a known fact
    /// - the receiver's `Brain` as the answer to a question with an inferred fact.
    public enum Answer: Equatable, ExpressibleByBooleanLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {

        case bool(Bool)
        case double(Double)
        case int(Int)
        case string(String)
        case comparable(ComparableAnswer)
        case equatable(EquatableAnswer)

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

        public static func == (lhs: Answer, rhs: Answer) -> Bool {
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
        
        init(answerWithDependendOnQuestions: AnswerWithDependencies) {
            self = answerWithDependendOnQuestions.answer
        }

        func asAnswerWithDependencies(_ dependencies: Dependencies = []) -> AnswerWithDependencies {
            return .init(answer: self, dependencies: dependencies)
        }

        public typealias ComparisonResult = Rules.Result<Predicate.EvaluationError, Bool>

        public func isEqual(to other: Answer) -> ComparisonResult {
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

        public func isNotEqual(to other: Answer) -> ComparisonResult {
            return isEqual(to: other).mapSuccess(!)
        }

        public func isLess(than other: Answer) -> ComparisonResult {
            switch (self, other) {
            case (.double(let it), .double(let other)): return .success(it < other)
            case (.int(let it), .int(let other)): return .success(it < other)
            case (.string(let it), .string(let other)): return .success(it < other)
            case (.comparable(let it), .comparable(let other)): return it.isLessThan(comparableAnswer: other)
            case (.bool, _), (.double, _), (.int, _), (.string, _), (.comparable, _), (.equatable, _): return .failed(.typeMismatch)
            }
        }

        public func isLessThanOrEqual(to other: Answer) -> ComparisonResult {
            return isLess(than: other).flatMapSuccess { lt in
                if lt { return .success(true) }
                else { return isEqual(to: other) }
            }
        }

        public func isGreater(than other: Answer) -> ComparisonResult {
            return isLessThanOrEqual(to: other).mapSuccess(!)
        }

        public func isGreaterThanOrEqual(to other: Answer) -> ComparisonResult {
            return isLess(than: other).mapSuccess(!)
        }

    }

    /// The questions asked while determining the answer to a question.
    public typealias Dependencies = Set<Question>

    /// Associates an answer with the questions that answer depended on.
    public struct AnswerWithDependencies: Equatable {
        public let answer: Answer
        public let dependencies: Facts.Dependencies
    }

    public typealias AnswerWithDependenciesResult = Rules.Result<AnswerError, AnswerWithDependencies>

    public typealias AnswerResult = Rules.Result<AnswerError, Answer>

    var known: [Question: AnswerWithDependencies]
    var inferred: [Question: AnswerWithDependencies]

    /// this maps a `Question` to the `Question`s that depended on the answer of
    /// that `Question` to produce their answer. Ergo, when the answer of a
    /// `Question` changes in `known`, all pairs in `inferred` keyed by members
    /// of the associated `[Question]` value of this dictionary must be
    /// invalidated. That is, the question:answer relationship here is
    /// depended-on:depending-on.
    var dependencies: [Question: Dependencies]

    public func know(answer: Answer, forQuestion question: Question) {
        known[question] = answer.asAnswerWithDependencies()
        forget(inferredAnswersDependentOn: question)
    }

    public func forget(answerForQuestion question: Question) {
        known.removeValue(forKey: question)
        forget(inferredAnswersDependentOn: question)
    }

    func forget(inferredAnswersDependentOn question: Question) {
        for inferredQuestionDependentOnAnsweredQuestion in (dependencies[question] ?? []) {
            inferred.removeValue(forKey: inferredQuestionDependentOnAnsweredQuestion)
        }
        dependencies.removeValue(forKey: question)
    }

    func cache(answer: AnswerWithDependencies, forQuestion question: Question) -> AnswerWithDependencies {
        inferred[question] = answer
        for dependedOnQuestion in answer.dependencies {
            dependencies[dependedOnQuestion, default: []].insert(question)
        }
        return answer
    }

    /// If an `Answer` cannot be provided for a question, an `AnswerError` is
    /// provided instead.
    public enum AnswerError: Swift.Error, Equatable {
        indirect case candidateEvaluationFailed(Predicate.EvaluationError)
        case noRuleFound(question: Question)
        case ambiguous(question: Question)
        case assignmentFailed(Brain.AssignmentError)
        case answerTypeDoesNotMatchAskType(Answer)
    }

    public func ask(question: Question) -> AnswerWithDependenciesResult {
        let answer = known[question] ?? inferred[question]
        return answer
            .map(AnswerWithDependenciesResult.success)
            ?? Fns.ask(
                question: question,
                given: self,
                onFailure: Rules.id,
                onSuccess: Fns.cache(question: question, given: self)
        )
    }

    /// Convenience method for `know` and `forget` that calls one or the other
    /// depending on whether `answer` is `.some` or `.none`.
    public func set<T>(answer: T?, forQuestion question: Question) where T: ComparableAnswer {
        return answer
            .map { know(answer: .comparable($0), forQuestion: question) }
            ?? forget(answerForQuestion: question)
    }

    /// Convenience method for `know` and `forget` that calls one or the other
    /// depending on whether `answer` is `.some` or `.none`.
    public func set<T>(answer: T?, forQuestion question: Question) where T: EquatableAnswer {
        return answer
            .map { know(answer: .equatable($0), forQuestion: question) }
            ?? forget(answerForQuestion: question)
    }

    /// Convenience method for `know` and `forget` that calls one or the other
    /// depending on whether `answer` is `.some` or `.none`.
    public func set(answer: Facts.Answer?, forQuestion question: Question) {
        return answer
            .map { know(answer: $0, forQuestion: question) }
            ?? forget(answerForQuestion: question)
    }

    public func ask(_ type: Bool.Type, question: Question) -> Rules.Result<AnswerError, Bool> {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, Bool> {
            if case .bool(let bool) = answerWithDependencies.answer {
                return .success(bool)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        switch ask(question: question) {
        case let .failed(error):
            return .failed(error)
        case let .success(answerWithDependencies):
            return cast(answerWithDependencies)
        }
    }

    public func ask(_ type: Int.Type, question: Question) -> Rules.Result<AnswerError, Int> {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, Int> {
            if case .int(let int) = answerWithDependencies.answer {
                return .success(int)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        switch ask(question: question) {
        case let .failed(error):
            return .failed(error)
        case let .success(answerWithDependencies):
            return cast(answerWithDependencies)
        }
    }

    public func ask(_ type: Double.Type, question: Question) -> Rules.Result<AnswerError, Double> {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, Double> {
            if case .double(let double) = answerWithDependencies.answer {
                return .success(double)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        switch ask(question: question) {
        case let .failed(error):
            return .failed(error)
        case let .success(answerWithDependencies):
            return cast(answerWithDependencies)
        }
    }

    public func ask(_ type: String.Type, question: Question) -> Rules.Result<AnswerError, String> {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, String> {
            if case .string(let string) = answerWithDependencies.answer {
                return .success(string)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        switch ask(question: question) {
        case let .failed(error):
            return .failed(error)
        case let .success(answerWithDependencies):
            return cast(answerWithDependencies)
        }
    }

    public func ask<T>(_ type: T.Type, question: Question) -> Rules.Result<AnswerError, T> where T: ComparableAnswer {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, T> {
            if case .comparable(let comparable) = answerWithDependencies.answer, let t = comparable as? T {
                return .success(t)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        switch ask(question: question) {
        case let .failed(error):
            return .failed(error)
        case let .success(answerWithDependencies):
            return cast(answerWithDependencies)
        }
    }

    public func ask<T>(_ type: T.Type, question: Question) -> Rules.Result<AnswerError, T> where T: EquatableAnswer {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, T> {
            if case .equatable(let equatable) = answerWithDependencies.answer, let t = equatable as? T {
                return .success(t)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        switch ask(question: question) {
        case let .failed(error):
            return .failed(error)
        case let .success(answerWithDependencies):
            return cast(answerWithDependencies)
        }
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

typealias Fns = FactsFunctions

/// Internal functions that are testable but not part of the
/// internal API of `Facts` itself
enum FactsFunctions {

    static func cache(
        question: Facts.Question,
        given facts: Facts
        ) -> (Facts.AnswerWithDependencies) -> Facts.AnswerWithDependencies
    {
        return { facts.cache(answer: $0, forQuestion: question) }
    }

    static func ask(
        question: Facts.Question,
        given facts: Facts,
        onFailure: (Facts.AnswerError) -> Facts.AnswerError,
        onSuccess: (Facts.AnswerWithDependencies) -> Facts.AnswerWithDependencies
        ) -> Facts.AnswerWithDependenciesResult {
        return facts
            .brain
            .ask(question: question, given: facts)
            .bimap(onFailure, onSuccess)
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
