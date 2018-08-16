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
    public struct Answer: Equatable {
        public let value: Any

        public let _isEquatableTo: (Answer) -> Bool
        public let _isComparableTo: ((Answer) -> Bool)?
        public let _isEqual: ((Answer) -> Bool)?
        public let _isLessThan: ((Answer) -> Bool)?

        init<T: Equatable>(equatable value: T) {
            self.value = value
            self._isEquatableTo = Answer.isEquatable(to: value)
            self._isComparableTo = nil
            self._isEqual = Answer.isEqual(lhs: value)
            self._isLessThan = nil
        }

        init<T: Comparable>(comparable value: T) {
            self.value = value
            self._isEquatableTo = Answer.isEquatable(to: value)
            self._isComparableTo = Answer.isComparable(to: value)
            self._isEqual = Answer.isEqual(lhs: value)
            self._isLessThan = Answer.isLess(lhs: value)
        }

        public static func == (lhs: Answer, rhs: Answer) -> Bool {
            return lhs.isEqual(to: rhs)
        }
        
        init(answerWithDependendOnQuestions: AnswerWithDependencies) {
            self = answerWithDependendOnQuestions.answer
        }

        func asAnswerWithDependencies(_ dependencies: Dependencies = []) -> AnswerWithDependencies {
            return .init(answer: self, dependencies: dependencies)
        }

        public func isEquatable(to answer: Answer) -> Bool {
            return _isEquatableTo(answer)
        }

        public func isEqual(to other: Answer) -> Bool {
            return _isEqual.map { $0(other) } ?? false
        }

        public func isNotEqual(to other: Answer) -> Bool {
            return !isEqual(to: other)
        }

        public func isComparable(to answer: Answer) -> Bool {
            return _isComparableTo.map { $0(answer) } ?? false
        }

        public func isLess(than other: Answer) -> Bool {
            return _isLessThan.map { $0(other) } ?? false
        }

        public func isLessThanOrEqual(to other: Answer) -> Bool {
            return isLess(than:other) || isEqual(to: other)
        }

        public func isGreater(than other: Answer) -> Bool {
            return !isLess(than:other)
        }

        public func isGreaterThanOrEqual(to other: Answer) -> Bool {
            return isGreater(than: other) || isEqual(to: other)
        }

        static func isEquatable<T: Equatable>(to answer: T) -> (Answer) -> Bool {
            return { other in (other.value as? T) != nil }
        }

        static func isComparable<T: Comparable>(to answer: T) -> (Answer) -> Bool {
            return { other in (other.value as? T) != nil }
        }

        static func isEqual<T: Equatable>(lhs: T) -> (Answer) -> Bool {
            return { rhs in
                guard let other = rhs.value as? T else {
                    return false
                }
                return lhs == other
            }
        }

        static func isLess<T: Comparable>(lhs: T) -> (Answer) -> Bool {
            return { rhs in
                guard let other = rhs.value as? T else {
                    return false
                }
                return lhs < other
            }
        }
    }

    /// The questions asked while determining the answer to a question.
    public typealias Dependencies = Set<Question>

    /// Associates an answer with the questions that answer depended on.
    public struct AnswerWithDependencies: Equatable {
        public let answer: Answer
        public let dependencies: Facts.Dependencies
        public var value: Any { return answer.value }
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
