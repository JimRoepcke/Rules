//
//  Context.swift
//  Rules
//  License: MIT, included below
//

public class Context {

    public typealias RHSKey = String
    public typealias RHSValue = String

    public let engine: Engine

    var stored: [RHSKey: Rule.Answer]
    var cached: [RHSKey: Rule.Answer]

    /// this maps a `RHSKey` to the `RHSKey`s that depended on the value of that `RHSKey` to produce their value
    /// ergo, when the value of a `RHSKey` changes in `stored`, all pairs in `cached` keyed by members of the associated `[RHSKey]` value
    /// of this dictionary must be invalidated.
    /// That is, the key:value relationship here is depended-on:dependent-keys
    var matched: [RHSKey: [RHSKey]]

    public init(engine: Engine) {
        self.engine = engine
        self.stored = [:]
        self.cached = [:]
        self.matched = [:]
    }

    public func store(answer: Rule.Answer, forKey key: RHSKey) {
        stored[key] = answer
        for cachedKeyDependentOnKey in (matched[key] ?? []) {
            cached.removeValue(forKey: cachedKeyDependentOnKey)
        }
        matched.removeValue(forKey: key)
    }

    func cache(lookup: Lookup, forKey key: RHSKey) -> Rule.Answer {
        let answer = lookup.answer
        cached[key] = answer
        for dependedOnKey in lookup.match {
            matched[dependedOnKey, default: []].append(key)
        }
        return answer
    }

    public enum AnswerError: Swift.Error, Equatable {
        case lookupFailed(Lookup.Error)
    }

    public subscript(key: RHSKey) -> Rules.Result<AnswerError, Rule.Answer> {
        get {
            if let value = stored[key] {
                return .success(value)
            }
            if let value = cached[key] {
                return .success(value)
            }
            return Fns.lookup(
                key: key,
                in: self,
                onFailure: Context.AnswerError.lookupFailed,
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
        ) -> (Lookup) -> Rule.Answer
    {
        return { context.cache(lookup: $0, forKey: key) }
    }

    static func lookup(
        key: Context.RHSKey,
        in context: Context,
        onFailure: (Lookup.Error) -> Context.AnswerError,
        onSuccess: (Lookup) -> Rule.Answer
        ) -> Rules.Result<Context.AnswerError, Rule.Answer> {
        return context
            .engine
            .lookup(key: key, in: context)
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
