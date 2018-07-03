//
//  Rule.swift
//  Rules
//  License: MIT, included below
//

/// Additional namespace for Rules-specific helpers to avoid ambiguity when
/// using other libraries with similar types.
public enum Rules {

    public enum Result<E, V>: Equatable where E: Equatable, V: Equatable {

        case failed(E)
        case success(V)

        public func bimap<W: Equatable, F: Equatable>(
            _ failed: (E) -> F,
            _ success: (V) -> W
            ) -> Result<F, W>
        {
            switch self {
            case .failed(let e): return .failed(failed(e))
            case .success(let v): return .success(success(v))
            }
        }
    }

    static func id<A>(_ a: A) -> A { return a }

    static func flip<A, B, C>(
        _ f: @escaping (A) -> (B) -> C
        ) -> (B) -> (A) -> C
    {
        return { b in { a in f(a)(b) } }
    }

    static func curry<A, B, C>(
        _ f: @escaping (A, B) -> C
        ) -> (A) -> (B) -> C
    {
        return { a in { b in f(a, b) } }
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
