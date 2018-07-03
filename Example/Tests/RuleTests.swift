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
                    let sut = "10: TRUEPREDICATE => key = value [assignment]"
                    let rule = parse(humanRule: sut)
                    switch rule {
                    case .failed(let error): fail("\(error)")
                    case .success(let rule):
                        expect(rule.priority) == 10
                        expect(rule.predicate) == .true
                    }
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