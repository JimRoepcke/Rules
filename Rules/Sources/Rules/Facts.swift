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
public struct Facts {

    /// Generates inferred facts via `Rule`s.
    public let brain: Brain

    /// The questions asked while determining the answer to a question.
    public typealias Dependencies = Set<Question>

    var cacheAnswers: Bool
    var known: [Question: AnswerWithDependencies]
    var inferred: [Question: AnswerWithDependencies]

    /// this maps a `Question` to the `Question`s that depended on the answer of
    /// that `Question` to produce their answer. Ergo, when the answer of a
    /// `Question` changes in `known`, all pairs in `inferred` keyed by members
    /// of the associated `[Question]` value of this dictionary must be
    /// invalidated. That is, the question:answer relationship here is
    /// depended-on:depending-on.
    var dependencies: [Question: Dependencies]

    public init(brain: Brain, cacheAnswers: Bool = false) {
        self.brain = brain
        self.cacheAnswers = cacheAnswers
        self.known = [:]
        self.inferred = [:]
        self.dependencies = [:]
    }

    public mutating func know(answer: Answer, forQuestion question: Question) {
        known[question] = answer.asAnswerWithDependencies(ambiguousRules: [])
        forget(inferredAnswersDependentOn: question)
    }

    public mutating func forget(answerForQuestion question: Question) {
        known.removeValue(forKey: question)
        forget(inferredAnswersDependentOn: question)
    }

    mutating func forget(inferredAnswersDependentOn question: Question) {
        guard cacheAnswers else {
            return
        }
        for inferredQuestionDependentOnAnsweredQuestion in (dependencies[question] ?? []) {
            inferred.removeValue(forKey: inferredQuestionDependentOnAnsweredQuestion)
        }
        dependencies.removeValue(forKey: question)
    }

    mutating func cache(answer: AnswerWithDependencies, forQuestion question: Question) -> AnswerWithDependencies {
        guard cacheAnswers else {
            return answer
        }
        inferred[question] = answer
        for dependedOnQuestion in answer.dependencies {
            dependencies[dependedOnQuestion, default: []].insert(question)
        }
        return answer
    }

    public mutating func ask(question: Question) -> AnswerWithDependenciesResult {
        let answer = known[question] ?? (cacheAnswers ? inferred[question] : nil)
        return answer
            .map(AnswerWithDependenciesResult.success)
            ?? brain
                .ask(question: question, given: &self)
                .mapSuccess { self.cache(answer: $0, forQuestion: question) }
    }

    /// Convenience method for `know` and `forget` that calls one or the other
    /// depending on whether `answer` is `.some` or `.none`.
    public mutating func set<T>(answer: T?, forQuestion question: Question) where T: ComparableAnswer {
        return answer
            .map { know(answer: .comparable($0), forQuestion: question) }
            ?? forget(answerForQuestion: question)
    }

    /// Convenience method for `know` and `forget` that calls one or the other
    /// depending on whether `answer` is `.some` or `.none`.
    public mutating func set<T>(answer: T?, forQuestion question: Question) where T: EquatableAnswer {
        return answer
            .map { know(answer: .equatable($0), forQuestion: question) }
            ?? forget(answerForQuestion: question)
    }

    /// Convenience method for `know` and `forget` that calls one or the other
    /// depending on whether `answer` is `.some` or `.none`.
    public mutating func set(answer: Facts.Answer?, forQuestion question: Question) {
        return answer
            .map { know(answer: $0, forQuestion: question) }
            ?? forget(answerForQuestion: question)
    }

    public mutating func ask(_ type: Bool.Type, question: Question) -> Rules.Result<AnswerError, Bool> {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, Bool> {
            if case .bool(let bool) = answerWithDependencies.answer {
                return .success(bool)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        return ask(question: question)
            .flatMapSuccess(cast)
    }

    public mutating func ask(_ type: Int.Type, question: Question) -> Rules.Result<AnswerError, Int> {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, Int> {
            if case .int(let int) = answerWithDependencies.answer {
                return .success(int)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        return ask(question: question)
            .flatMapSuccess(cast)
    }

    public mutating func ask(_ type: Double.Type, question: Question) -> Rules.Result<AnswerError, Double> {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, Double> {
            if case .double(let double) = answerWithDependencies.answer {
                return .success(double)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        return ask(question: question)
            .flatMapSuccess(cast)
    }

    public mutating func ask(_ type: String.Type, question: Question) -> Rules.Result<AnswerError, String> {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, String> {
            if case .string(let string) = answerWithDependencies.answer {
                return .success(string)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        return ask(question: question)
            .flatMapSuccess(cast)
    }

    public mutating func ask<T>(_ type: T.Type, question: Question) -> Rules.Result<AnswerError, T> where T: ComparableAnswer {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, T> {
            if case .comparable(let comparable) = answerWithDependencies.answer, let t = comparable as? T {
                return .success(t)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        return ask(question: question)
            .flatMapSuccess(cast)
    }

    public mutating func ask<T>(_ type: T.Type, question: Question) -> Rules.Result<AnswerError, T> where T: EquatableAnswer {
        func cast(_ answerWithDependencies: AnswerWithDependencies) -> Rules.Result<AnswerError, T> {
            if case .equatable(let equatable) = answerWithDependencies.answer, let t = equatable as? T {
                return .success(t)
            }
            return .failed(.answerTypeDoesNotMatchAskType(answerWithDependencies.answer))
        }
        return ask(question: question)
            .flatMapSuccess(cast)
    }
}

private typealias Fns = FactsFunctions

/// Internal functions that are testable but not part of the
/// internal API of `Facts` itself
enum FactsFunctions {

    static func ask(
        question: Facts.Question,
        given facts: inout Facts,
        onFailure: (Facts.AnswerError) -> Facts.AnswerError,
        onSuccess: (Facts.AnswerWithDependencies) -> Facts.AnswerWithDependencies
        ) -> Facts.AnswerWithDependenciesResult {
        return facts
            .brain
            .ask(question: question, given: &facts)
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
