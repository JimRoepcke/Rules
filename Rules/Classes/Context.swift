//
//  Facts.swift
//  Rules
//  License: MIT, included below
//

/// A mutable collection of answers to questions, both known and inferred.
///
/// **Known facts** are provided directly by the client of the `Facts`. Use
/// the `store(answer:forQuestion:)` method to create a known fact.
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
/// asked questions. It knows which other questions, stored and inferred, that
/// were considered when producing the inferred answer, and automatically
/// invalidates its memory (cache) when dependencies change.
public class Facts {

    public struct Question: Hashable, Codable, ExpressibleByStringLiteral {
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
    }

    public enum Answer: Equatable {
        case bool(Bool)
        case double(Double)
        case int(Int)
        case string(String)

        func asAnswerWithDependencies(_ dependencies: Set<Question> = []) -> AnswerWithDependencies {
            switch self {
            case let .bool(it): return .bool(it, dependencies: dependencies)
            case let .double(it): return .double(it, dependencies: dependencies)
            case let .int(it): return .int(it, dependencies: dependencies)
            case let .string(it): return .string(it, dependencies: dependencies)
            }
        }

        init(answerWithDependendOnQuestions: AnswerWithDependencies) {
            self = answerWithDependendOnQuestions.answer
        }
    }

    public enum AnswerWithDependencies: Equatable {
        case bool(Bool, dependencies: Set<Question>)
        case double(Double, dependencies: Set<Question>)
        case int(Int, dependencies: Set<Question>)
        case string(String, dependencies: Set<Question>)

        var answer: Answer {
            switch self {
            case .bool(let it, _): return .bool(it)
            case .double(let it, _): return .double(it)
            case .int(let it, _): return .int(it)
            case .string(let it, _): return .string(it)
            }
        }

        var dependencies: Set<Question> {
            switch self {
            case .bool(_, let it): return it
            case .double(_, let it): return it
            case .int(_, let it): return it
            case .string(_, let it): return it
            }
        }
    }

    public let engine: Brain

    var stored: [Question: AnswerWithDependencies]
    var cached: [Question: AnswerWithDependencies]

    /// this maps a `Question` to the `Question`s that depended on the answer of
    /// that `Question` to produce their answer. Ergo, when the answer of a
    /// `Question` changes in `stored`, all pairs in `cached` keyed by members
    /// of the associated `[Question]` value of this dictionary must be
    /// invalidated. That is, the question:answer relationship here is
    /// depended-on:dependent-keys.
    var dependencies: [Question: Set<Question>]

    public init(engine: Brain) {
        self.engine = engine
        self.stored = [:]
        self.cached = [:]
        self.dependencies = [:]
    }

    public func store(answer: Answer, forQuestion question: Question) {
        stored[question] = answer.asAnswerWithDependencies()
        for cachedQuestionDependentOnAnsweredQuestion in (dependencies[question] ?? []) {
            cached.removeValue(forKey: cachedQuestionDependentOnAnsweredQuestion)
        }
        dependencies.removeValue(forKey: question)
    }

    func cache(answer: AnswerWithDependencies, forQuestion question: Question) -> AnswerWithDependencies {
        cached[question] = answer
        for dependedOnQuestion in answer.dependencies {
            dependencies[dependedOnQuestion, default: []].insert(question)
        }
        return answer
    }

    public enum AnswerError: Swift.Error, Equatable {
        case noRuleFound(question: Question)
        case ambiguous(question: Question)
        case firingFailed(Rule.FiringError)
    }

    public func ask(question: Question) -> AnswerResult {
        return self[question].bimap(Rules.id, Facts.Answer.init)
    }

    public subscript(question: Question) -> AnswerWithDependenciesResult {
        get {
            if let answer = stored[question] {
                return .success(answer)
            }
            if let answer = cached[question] {
                return .success(answer)
            }
            return Fns.ask(
                question: question,
                in: self,
                onFailure: Rules.id,
                onSuccess: Fns.cache(question: question, in: self)
            )
        }
    }
}

public typealias AnswerResult = Rules.Result<Facts.AnswerError, Facts.Answer>

typealias Fns = FactsFunctions

/// Internal functions that are testable but not part of the
/// internal API of `Facts` itself
enum FactsFunctions {

    static func cache(
        question: Facts.Question,
        in context: Facts
        ) -> (Facts.AnswerWithDependencies) -> Facts.AnswerWithDependencies
    {
        return { context.cache(answer: $0, forQuestion: question) }
    }

    static func ask(
        question: Facts.Question,
        in context: Facts,
        onFailure: (Facts.AnswerError) -> Facts.AnswerError,
        onSuccess: (Facts.AnswerWithDependencies) -> Facts.AnswerWithDependencies
        ) -> AnswerWithDependenciesResult {
        return context
            .engine
            .ask(question: question, in: context)
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
