//
//  Context.swift
//  Rules
//  License: MIT, included below
//

public class Context {

    public typealias RHSKey = String
    public typealias RHSValue = String

    public enum Answer: Equatable {
        case bool(Bool, match: Set<RHSKey>)
        case double(Double, match: Set<RHSKey>)
        case int(Int, match: Set<RHSKey>)
        case string(String, match: Set<RHSKey>)

        var match: Set<RHSKey> {
            switch self {
            case .bool(_, let it): return it
            case .double(_, let it): return it
            case .int(_, let it): return it
            case .string(_, let it): return it
            }
        }
    }

    public let engine: Engine

    var stored: [RHSKey: Answer]
    var cached: [RHSKey: Answer]

    /// this maps a `RHSKey` to the `RHSKey`s that depended on the value of that `RHSKey` to produce their value
    /// ergo, when the value of a `RHSKey` changes in `stored`, all pairs in `cached` keyed by members of the associated `[RHSKey]` value
    /// of this dictionary must be invalidated.
    /// That is, the key:value relationship here is depended-on:dependent-keys
    var matched: [RHSKey: Set<RHSKey>]

    public init(engine: Engine) {
        self.engine = engine
        self.stored = [:]
        self.cached = [:]
        self.matched = [:]
    }

    public func store(answer: Answer, forKey key: RHSKey) {
        stored[key] = answer
        for cachedKeyDependentOnKey in (matched[key] ?? []) {
            cached.removeValue(forKey: cachedKeyDependentOnKey)
        }
        matched.removeValue(forKey: key)
    }

    func cache(answer: Answer, forKey key: RHSKey) -> Answer {
        cached[key] = answer
        for dependedOnKey in answer.match {
            matched[dependedOnKey, default: []].insert(key)
        }
        return answer
    }

    public enum AnswerError: Swift.Error, Equatable {
        case noRuleFound(key: RHSKey)
        case ambiguous(key: RHSKey)
        case firingFailed(Rule.FiringError)
    }

    public subscript(key: RHSKey) -> QuestionWithMatchResult {
        get {
            if let value = stored[key] {
                return .success(value)
            }
            if let value = cached[key] {
                return .success(value)
            }
            return Fns.question(
                key: key,
                in: self,
                onFailure: Rules.id,
                onSuccess: Fns.cache(key: key, in: self)
            )
        }
    }
}

typealias Fns = ContextFunctions

/// Internal functions that are testable but not part of the
/// internal API of `Context` itself
enum ContextFunctions {

    static func cache(
        key: Context.RHSKey,
        in context: Context
        ) -> (Context.Answer) -> Context.Answer
    {
        return { context.cache(answer: $0, forKey: key) }
    }

    static func question(
        key: Context.RHSKey,
        in context: Context,
        onFailure: (Context.AnswerError) -> Context.AnswerError,
        onSuccess: (Context.Answer) -> Context.Answer
        ) -> QuestionWithMatchResult {
        return context
            .engine
            .question(key: key, in: context)
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
