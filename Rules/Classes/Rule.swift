//
//  Rule.swift
//  Rules
//  License: MIT, included below
//

/// - note: a `Rule` is invalid if its (LHS) predicate looks up the (RHS) `key`
public struct Rule {

    public enum FiringError: Swift.Error, Equatable {
        case failed
        case invalidRHSValue(String)
    }

    public typealias FiringResult = Rules.Result<FiringError, Context.Answer>

    public typealias Assignment = (Rule, Context) -> FiringResult

    public let priority: Int
    public let predicate: Predicate
    public let key: Context.RHSKey
    public let value: Context.RHSValue
    public let assignment: Assignment

    func fire(in context: Context) -> FiringResult {
        return assignment(self, context)
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
