//
//  RuleTests.swift
//  Rules
//  License: MIT, included below
//

// deal with Quick/Nimble naming conflict
@testable import enum Rules.Predicate
typealias RulesPredicate = Predicate

import Quick
import Nimble

@testable import Rules

class RuleTests: QuickSpec {
    override func spec() {

        describe("Rule") {

            describe("parse(humanRule:)") {

                it("parses?") {
                    let sut = "10: TRUEPREDICATE => jim = roepcke"
                    let rule = parse(humanRule: sut)
                    switch rule {
                    case .failed(let error): fail("\(error)")
                    case .success(let rule):
                        expect(rule.priority) == 10
                        expect(rule.predicate) == .true
                        expect(rule.question) == "jim"
                        expect(rule.answer) == "roepcke"
                    }
                }

                it("parses a complex predicate") {
                    let sut = "10: (firstName = 'Jim' AND lastName = 'Roepcke') OR (city = 'Edmonton') => favouriteTeam = Oilers"
                    let rule = parse(humanRule: sut)
                    switch rule {
                    case .failed(let error): fail("\(error)")
                    case .success(let rule):
                        expect(rule.priority) == 10
                        expect(rule.predicate) == RulesPredicate.or(
                            [
                                .and(
                                    [
                                        .comparison(lhs: .question("firstName"), op: .isEqualTo, rhs: .answer(.string("Jim"))),
                                        .comparison(lhs: .question("lastName"), op: .isEqualTo, rhs: .answer(.string("Roepcke")))
                                    ]
                                ),
                                .comparison(lhs: .question("city"), op: .isEqualTo, rhs: .answer(.string("Edmonton")))
                            ]
                        )
                        expect(rule.question) == "favouriteTeam"
                        expect(rule.answer) == "Oilers"
                        expect(rule.assignment).to(beNil())
                    }
                }
            }

            describe("parse(factAnswer:)") {

                it("fails to parse empty input") {
                    expect(parse(factAnswer: "")) == .failed(.factAnswerNotFound)
                }

                it("parses input not beginning with (") {
                    expect(parse(factAnswer: "word")) == .success(.init(answer: "word", assignment: nil))
                }

                it("parses input beginning with (") {
                    expect(parse(factAnswer: "(string)word")) == .success(.init(answer: "word", assignment: nil))
                }

                it("parses (string)") {
                    expect(parse(factAnswer: "(string)")) == .success(.init(answer: "", assignment: nil))
                }

                it("parses (string))") {
                    expect(parse(factAnswer: "(string))")) == .success(.init(answer: ")", assignment: nil))
                }

                it("parses (string)x)") {
                    expect(parse(factAnswer: "(string)x)")) == .success(.init(answer: "x)", assignment: nil))
                }

                it("parses (string)()") {
                    expect(parse(factAnswer: "(string)()")) == .success(.init(answer: "()", assignment: nil))
                }

                it("fails to parse when input begins with ( but does not contain )") {
                    expect(parse(factAnswer: "(stringword")) == .failed(.factAnswerAssignmentClosingDelimiterNotFound)
                }
            }

            describe("parse(humanRuleFileContents:)") {

                it("parses an empty file") {
                    expect(parse(humanRuleFileContents: "")) == .success([])
                }

                it("parses a file with one comment") {
                    let sut = "// a comment"
                    expect(parse(humanRuleFileContents: sut)) == .success([])
                }

                it("parses a file with one line") {
                    let sut = "10: TRUEPREDICATE => jim = roepcke"
                    let expected = Rule(
                        priority: 10,
                        predicate: .true,
                        question: "jim",
                        answer: "roepcke",
                        assignment: nil
                    )
                    expect(parse(humanRuleFileContents: sut)) == .success([.init(lineNumber: 1, line: sut, rule: expected)])
                }

                it("parses a file with one line with an assignment") {
                    let sut = "10: TRUEPREDICATE => jim = (string)roepcke"
                    let expected = Rule(
                        priority: 10,
                        predicate: .true,
                        question: "jim",
                        answer: "roepcke",
                        assignment: nil
                    )
                    expect(parse(humanRuleFileContents: sut)) == .success([.init(lineNumber: 1, line: sut, rule: expected)])
                }

                it("parses a file with one line with a custom assignment") {
                    let sut = "10: TRUEPREDICATE => jim = (custom)roepcke"
                    let expected = Rule(
                        priority: 10,
                        predicate: .true,
                        question: "jim",
                        answer: "roepcke",
                        assignment: "custom"
                    )
                    expect(parse(humanRuleFileContents: sut)) == .success([.init(lineNumber: 1, line: sut, rule: expected)])
                }

                it("parses a file with two lines") {
                    let line = "10: TRUEPREDICATE => jim = roepcke"
                    let sut = "\(line)\n\(line)"
                    let expected = Rule(
                        priority: 10,
                        predicate: .true,
                        question: "jim",
                        answer: "roepcke",
                        assignment: nil
                    )
                    let parsed1 = ParsedHumanRule(lineNumber: 1, line: line, rule: expected)
                    let parsed2 = ParsedHumanRule(lineNumber: 2, line: line, rule: expected)
                    expect(parse(humanRuleFileContents: sut)) == .success([parsed1, parsed2])
                }

                it("parses a file with two lines and comments") {
                    let line = "10: TRUEPREDICATE => jim = roepcke"
                    let sut = "\t// a comment\n\(line)\n// a comment\n\(line)\n// another comment"
                    let expected = Rule(
                        priority: 10,
                        predicate: .true,
                        question: "jim",
                        answer: "roepcke",
                        assignment: nil
                    )
                    let parsed2 = ParsedHumanRule(lineNumber: 2, line: line, rule: expected)
                    let parsed4 = ParsedHumanRule(lineNumber: 4, line: line, rule: expected)
                    expect(parse(humanRuleFileContents: sut)) == .success([parsed2, parsed4])
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
