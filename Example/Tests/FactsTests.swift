//
//  FactsTests.swift
//  Rules
//  License: MIT, included below
//

import Quick
import Nimble

@testable import Rules

extension Facts.AnswerError {
    static let mock: Facts.AnswerError = .noRuleFound(question: "aQuestion")
}

extension Brain {
    static let mockf: () -> Brain = Brain.init
}

extension Facts {
    static func mockf(brain: Brain = .mockf()) -> Facts {
        return .init(brain: brain)
    }
}

class FactsTests: QuickSpec {
    override func spec() {

        typealias Fns = FactsFunctions

        describe("FactsFunctions") {

            describe("lookup") {

                it("fails to answer a question when it does not know the answer and no rules were found for that question") {
                    var facts: Facts = .mockf()

                    let result = facts.ask(question: "missing")

                    expect(result) == Facts.AnswerWithDependenciesResult.failed(.noRuleFound(question: "missing"))
                }

            }

            describe("set") {

                var sut: Facts?

                beforeEach {
                    sut = Facts.mockf(brain: .mockf())
                }

                afterEach {
                    sut = nil
                }

                it("can set a string") {
                    guard var sut = sut else { return fail() }
                    let answer: Facts.Answer? = "test"
                    sut.set(answer: answer, forQuestion: "test")
                    expect(sut.known["test"]) == Facts.AnswerWithDependencies.init(answer: "test", dependencies: [])
                }

                it("can forget a string") {
                    guard var sut = sut else { return fail() }
                    let answer: Facts.Answer? = nil
                    sut.know(answer: "test", forQuestion: "test")
                    sut.set(answer: answer, forQuestion: "test")
                    expect(sut.known["test"]).to(beNil())
                }
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
