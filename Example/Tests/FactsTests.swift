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

        describe("Reporting Ambiguity with inferred answers") {

            var rules: [Rule]?
            var brain: Brain?

            beforeEach {
                let rule1 = Rule(
                    priority: 1,
                    predicate: .true,
                    question: "question",
                    answer: "answer1",
                    assignment: nil
                )
                let rule2 = Rule(
                    priority: 1,
                    predicate: .true,
                    question: "question",
                    answer: "answer2",
                    assignment: nil
                )
                rules = [rule1, rule2]
                brain = Brain()
            }

            afterEach {
                rules = nil
                brain = nil
            }

            context("one rule") {

                beforeEach {
                    guard let rules = rules else { return fail() }
                    brain?.add(rules: [rules[0]])
                }

                afterEach {
                }

                it("reports the rules as ambiguous when asking the question") {
                    guard let brain = brain else { return fail() }
                    var facts = Facts.init(brain: brain, cacheAnswers: false)
                    let result = facts.ask(question: "question")
                    switch result {
                    case let .failed(error):
                        fail("asking \"question\" should not have failed. received: \(error)")
                    case let .success(answerWithDependencies):
                        let ambiguousRules = answerWithDependencies.ambiguousRules.flatMap({ $0 })
                        expect(ambiguousRules).to(beEmpty())
                    }
                }
            }

            context("two mutually-exclusive rules sharing the same priority & predicate size") {

                beforeEach {
                    guard let rules = rules else { return fail() }
                    var rule3 = rules[0]
                    rule3.predicate = .false
                    brain?.add(rules: [rule3, rules[1]])
                }

                it("reports the rules as unambiguous when asking the question") {
                    guard let brain = brain else { return fail() }
                    var facts = Facts.init(brain: brain, cacheAnswers: false)
                    let result = facts.ask(question: "question")
                    switch result {
                    case let .failed(error):
                        fail("asking \"question\" should not have failed. received: \(error)")
                    case let .success(answerWithDependencies):
                        let ambiguousRules = answerWithDependencies.ambiguousRules.flatMap({ $0 })
                        expect(ambiguousRules).to(beEmpty())
                    }
                }
            }

            context("two non-mutually-exclusive rules sharing the same priority & predicate size") {

                beforeEach {
                    guard let rules = rules else { return fail() }
                    brain?.add(rules: rules)
                }

                afterEach {
                    brain = nil
                }

                it("reports the rules as ambiguous when asking the question") {
                    guard let brain = brain, let rules = rules else { return fail() }
                    var facts = Facts.init(brain: brain, cacheAnswers: false)
                    let result = facts.ask(question: "question")
                    switch result {
                    case let .failed(error):
                        fail("asking \"question\" should not have failed. received: \(error)")
                    case let .success(answerWithDependencies):
                        let ambiguousRules = answerWithDependencies.ambiguousRules.flatMap({ $0 })
                        expect(ambiguousRules.count) == 2
                        expect(ambiguousRules.contains(rules[0])).to(beTrue())
                        expect(ambiguousRules.contains(rules[1])).to(beTrue())
                    }
                }
            }

            context("two pairs of non-mutually-exclusive rules sharing the same priority & predicate size") {

                beforeEach {
                    guard var copy = rules else { return fail() }
                    copy[0].answer = "same"
                    copy[1].answer = "same"
                    copy.append(Rule.init(
                        priority: 1,
                        predicate: .comparison(lhs: .question("question"), op: .isEqualTo, rhs: .answer("same")),
                        question: "deeper",
                        answer: "answer1",
                        assignment: nil
                    ))
                    copy.append(Rule.init(
                        priority: 1,
                        predicate: .comparison(lhs: .question("question"), op: .isEqualTo, rhs: .answer("same")),
                        question: "deeper",
                        answer: "answer2",
                        assignment: nil
                    ))
                    brain?.add(rules: copy)
                    rules = copy
                }

                it("reports the rules as ambiguous when asking the question") {
                    guard let brain = brain, let rules = rules else { return fail() }
                    var facts = Facts.init(brain: brain, cacheAnswers: false)
                    let result = facts.ask(question: "deeper")
                    switch result {
                    case let .failed(error):
                        fail("asking \"deeper\" should not have failed. received: \(error)")
                    case let .success(answerWithDependencies):
                        let ambiguousRules = answerWithDependencies.ambiguousRules.flatMap({ $0 })
                        print(ambiguousRules)
                        // evaluating the first deeper rule evaluates the question rule
                        // that adds the two question rules (total 2)
                        // evaluating the second deeper rule evaluations the question rule
                        // that adds the two question rules (total 4)
                        // evaluating all the rules finds the deeper rules were ambiguous
                        // that adds the two deeper rules (total 6)
                        expect(ambiguousRules.count) == 6
                        expect(ambiguousRules.contains(rules[0])).to(beTrue())
                        expect(ambiguousRules.contains(rules[1])).to(beTrue())
                        expect(ambiguousRules.contains(rules[2])).to(beTrue())
                        expect(ambiguousRules.contains(rules[3])).to(beTrue())
                    }
                }
            }
        }

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
                    expect(sut.known["test"]) == Facts.AnswerWithDependencies.init(answer: "test", dependencies: [], ambiguousRules: [])
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
