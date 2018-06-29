//
//  Predicate.swift
//  Rules
//  License: MIT, included below
//

public struct Predicate {

    public typealias Match = [Context.RHSKey]

    /// - returns: nil if the context does not match, otherwise the keys used while matching
    typealias Fn = (Context) -> Match?

    let f: Fn

    // TODO: give the predicate a fingerprint (a hash value) so that we can
    // cache predicate evaluations
    // when a match comes in, we would include the predicate's hash. Then,
    // when finding candidate rules, we can check the predicate evaluation
    // cache for a result before evaluating the predicate.

    /// `size` helps break ties between multiple candidate rules with the same
    /// priority if this predicate is a conjunction, it is the number of
    /// operands in the conjunction.
    /// otherwise, it is the largest number of conjunctions amongst its
    /// disjunctive operands.
    /// the size of `{ _ in nil }` is `0` (and represents the predicate that never matches)
    /// the size of `{ _ in [] }` is `0` (and represents the predicate that always matches)
    /// the size of `{ context in context[foo] == someValue ? [foo] : nil }` is `1`
    /// the size of `{ context in context[foo] == someValue || context[foo] == otherValue ? [foo] : nil }` is `1`
    /// the size of `{ context in context[foo] == someValue && context[bar] == otherValue ? [foo, bar] : nil }` is `2`
    public let size: Int

    public func matches(in context: Context) -> Match? {
        return f(context)
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
