//
//  Rule.swift
//  Rules
//  License: MIT, included below
//

/// Additional namespace for Rules-specific helpers to avoid ambiguity when
/// using other libraries with similar types.
public enum Rules {

    /// A sum type with `failed` and `success` cases.
    ///
    /// In order to not conflict with other implementations of `Result`, this
    /// implementation is nested inside the `Rules` namespace.
    public enum Result<E, V> {

        case failed(E)
        case success(V)

        /// Returns the associated value of the `.success` case, if applicable,
        /// otherwise returns `nil`.
        public var value: V? {
            switch self {
            case .failed: return nil
            case .success(let value): return value
            }
        }

        /// Transforms a `Result` into another `Result`.
        public func bimap<W, F>(
            _ failed: (E) -> F,
            _ success: (V) -> W
            ) -> Rules.Result<F, W>
        {
            switch self {
            case .failed(let e): return .failed(failed(e))
            case .success(let v): return .success(success(v))
            }
        }

        public func flattenSuccess<U>() -> Result<E, U> where V == Result<E, U> {
            switch self {
            case let .success(.success(value)): return .success(value)
            case let .success(.failed(error)): return .failed(error)
            case let .failed(error): return .failed(error)
            }
        }

        public func mapSuccess<U>(_ f: (V) -> U) -> Result<E, U> {
            switch self {
            case let .failed(error):
                return .failed(error)
            case let .success(value):
                return .success(f(value))
            }
        }

        public func flatMapSuccess<U>(_ f: (V) -> Result<E, U>) -> Result<E, U> {
            return mapSuccess(f).flattenSuccess()
        }
    }

    /// The canonical identity function. Simply returns the value it's given.
    static func id<A>(_ a: A) -> A { return a }

    /// Swaps the order of the parameters of a curried binary function.
    /// Helpful when trying to partially apply an instance method.
    static func flip<A, B, C>(
        _ f: @escaping (A) -> (B) -> C
        ) -> (B) -> (A) -> C
    {
        return { b in { a in f(a)(b) } }
    }

    /// Returns a unary function that returns a unary function that calls the
    /// provided binary function and returns its result.
    static func curry<A, B, C>(
        _ f: @escaping (A, B) -> C
        ) -> (A) -> (B) -> C
    {
        return { a in { b in f(a, b) } }
    }

}

extension Rules.Result: Equatable where E: Equatable, V: Equatable {

    public static func == <E: Equatable, V: Equatable>(lhs: Rules.Result<E, V>, rhs: Rules.Result<E, V>) -> Bool {
        switch (lhs, rhs) {
        case let (.failed(le), .failed(re)): return le == re
        case let (.success(lv), .success(rv)): return lv == rv
        default: return false
        }
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
