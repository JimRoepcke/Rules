//
//  ContextTests.swift
//  Rules
//  License: MIT, included below
//

import Quick
import Nimble

@testable import Rules

extension Context.AnswerError {
    static let mock: Context.AnswerError = .noRuleFound(key: "key")
}

extension Engine {
    static let mockf: () -> Engine = Engine.init
}

extension Context {
    static func mockf(engine: Engine = .mockf()) -> Context {
        return .init(engine: engine)
    }
}

class ContextTests: QuickSpec {
    override func spec() {

        typealias Fns = ContextFunctions

        describe("ContextFunctions") {

            describe("lookup") {
                var failed = false
                var succeeded = false
                let onF: (Context.AnswerError) -> Context.AnswerError = {
                    failed = true
                    return $0
                }
                let onS: (Context.Answer) -> Context.Answer = {
                    succeeded = true
                    return $0
                }

                let result = Fns.lookup(
                    key: "missing",
                    in: .mockf(),
                    onFailure: onF,
                    onSuccess: onS
                )

                expect(result) == LookupResult.failed(.noRuleFound(key: "missing"))

                expect(failed).to(beTrue())
                expect(succeeded).to(beFalse())

            }
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
