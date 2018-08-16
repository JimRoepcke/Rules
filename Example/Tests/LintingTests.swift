//
//  LintingTests.swift
//  Rules
//  License: MIT, included below
//

// deal with Quick/Nimble naming conflict
@testable import enum Rules.Predicate

import Quick
import Nimble

@testable import Rules

class LintingTests: QuickSpec {
    override func spec() {

        describe("Linting") {

            describe("linter(parsed:spec:)") {
                it("does not find lint when there are no rules and no spec") {
                    expect(linter(parsed: [], spec: nil) == []).to(beTrue())
                }
            }

            describe("checkFallbackRulesExist(parsed:spec:)") {
                it("finds lint when there are no rules but there are rhs questions specified") {
                    let spec = LinterSpecification(lhs: [:], rhs: ["aQuestion": .any])
                    expect(checkFallbackRulesExist(parsed: [], spec: spec) == [(nil, "no fallback rule found for aQuestion")]).to(beTrue())
                }
                it("finds lint when there is a rule but it isn't a fallback rule") {
                    let spec = LinterSpecification(lhs: [:], rhs: ["aQuestion": .any])
                    let parsed = ParsedHumanRule(
                        lineNumber: 1,
                        line: "10: this = 'that' => aQuestion = answer",
                        rule: .init(
                            priority: 10,
                            predicate: .comparison(lhs: .question("this"), op: .isEqualTo, rhs: .answer(.init(comparable: "that"))),
                            question: "aQuestion",
                            answer: "answer",
                            assignment: nil
                        )
                    )
                    expect(checkFallbackRulesExist(parsed: [parsed], spec: spec) == [(nil, "no fallback rule found for aQuestion")]).to(beTrue())
                }
                it("does not find lint when there is a rule and it is a fallback rule") {
                    let spec = LinterSpecification(lhs: [:], rhs: ["aQuestion": .any])
                    let parsed = ParsedHumanRule(
                        lineNumber: 1,
                        line: "0: true => aQuestion = answer",
                        rule: .init(
                            priority: 0,
                            predicate: .true,
                            question: "aQuestion",
                            answer: "answer",
                            assignment: nil
                        )
                    )
                    expect(checkFallbackRulesExist(parsed: [parsed], spec: spec).isEmpty).to(beTrue())
                }
            }
        }
    }
}

func == (lhs: RuleLint, rhs: RuleLint) -> Bool {
    return lhs.0 == rhs.0
        && lhs.1 == rhs.1
}

func == (lhs: [RuleLint], rhs: [RuleLint]) -> Bool {
    return lhs.count == rhs.count
        && zip(lhs, rhs).reduce(true) { result, pair in result && (pair.0 == pair.1) }
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
