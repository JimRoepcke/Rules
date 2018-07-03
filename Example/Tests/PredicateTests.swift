//
//  PredicateTests.swift
//  Rules
//  License: MIT, included below
//

// deal with Quick/Nimble naming conflict
@testable import enum Rules.Predicate
typealias SUT = Predicate

import Quick
import Nimble

@testable import Rules

class PredicateTests: QuickSpec {
    override func spec() {

        describe("Predicate") {

            describe("evaluation") {

                var falseNoKeys: SUT.EvaluationResult {
                    return .success(.init(value: false, keys: []))
                }

                var trueNoKeys: SUT.EvaluationResult {
                    return .success(.init(value: true, keys: []))
                }

                it("returns false for .false") {
                    let sut = SUT.false
                    let result = evaluate(predicate: sut, in: .mockf())
                    expect(result) == falseNoKeys
                }

                it("returns true for .true") {
                    let sut = SUT.true
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == trueNoKeys
                }

                it("returns true for .not(.false)") {
                    let sut = SUT.not(.false)
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == trueNoKeys
                }

                it("returns false for .not(.true)") {
                    let sut = SUT.not(.true)
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == falseNoKeys
                }

                it("returns false for .and([.false, .false])") {
                    let sut = SUT.and([.false, .false])
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == falseNoKeys

                }

                it("returns false for .and([.false, .true])") {
                    let sut = SUT.and([.false, .true])
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == falseNoKeys

                }

                it("returns false for .and([.true, .false])") {
                    let sut = SUT.and([.true, .false])
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == falseNoKeys

                }

                it("returns true for .and([.true, .true])") {
                    let sut = SUT.and([.true, .true])
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == trueNoKeys

                }

                it("returns false for .or([.false, .false])") {
                    let sut = SUT.or([.false, .false])
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == falseNoKeys

                }

                it("returns true for .or([.false, .true])") {
                    let sut = SUT.or([.false, .true])
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == trueNoKeys

                }

                it("returns true for .or([.true, .false])") {
                    let sut = SUT.or([.true, .false])
                    let result = evaluate(predicate: sut, in: .mockf())

                    expect(result) == trueNoKeys

                }

                it("returns true for .or([.true, .true])") {
                    let sut = SUT.or([.true, .true])
                    let result = evaluate(predicate: sut, in: .mockf())
                    expect(result) == trueNoKeys

                }

                it("can check equality of boolean values") {
                    let sut = SUT.comparison(lhs: .predicate(.false), op: .isEqualTo, rhs: .predicate(.false))
                    let result = evaluate(predicate: sut, in: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can check equality of int values") {
                    let sut = SUT.comparison(lhs: .value(.int(0)), op: .isEqualTo, rhs: .value(.int(0)))
                    let result = evaluate(predicate: sut, in: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can check equality of double values") {
                    let sut = SUT.comparison(lhs: .value(.double(0)), op: .isEqualTo, rhs: .value(.double(0)))
                    let result = evaluate(predicate: sut, in: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can check equality of string values") {
                    let sut = SUT.comparison(lhs: .value(.string("0")), op: .isEqualTo, rhs: .value(.string("0")))
                    let result = evaluate(predicate: sut, in: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can compare int values") {
                    let sut = SUT.comparison(lhs: .value(.int(0)), op: .isLessThan, rhs: .value(.int(1)))
                    let result = evaluate(predicate: sut, in: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can compare double values") {
                    let sut = SUT.comparison(lhs: .value(.double(0)), op: .isLessThan, rhs: .value(.double(1)))
                    let result = evaluate(predicate: sut, in: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can compare string values") {
                    let sut = SUT.comparison(lhs: .value(.string("0")), op: .isLessThan, rhs: .value(.string("1")))
                    let result = evaluate(predicate: sut, in: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can check equality of the same key") {
                    let sut = SUT.comparison(lhs: .key(.init(value: "test")), op: .isEqualTo, rhs: .key(.init(value: "test")))
                    let context = Context.mockf()
                    context.store(answer: .int(0, match: []), forKey: "test")
                    let result = evaluate(predicate: sut, in: context)
                    expect(result) == .success(.init(value: true, keys: ["test"]))
                    // this answer will be true even if the value changes, so no dependent keys
                }

                it("can check inequality of the same key") {
                    let sut = SUT.comparison(lhs: .key(.init(value: "test")), op: .isNotEqualTo, rhs: .key(.init(value: "test")))
                    let context = Context.mockf()
                    context.store(answer: .int(0, match: []), forKey: "test")
                    let result = evaluate(predicate: sut, in: context)
                    expect(result) == .success(.init(value: false, keys: ["test"]))
                    // this answer will be false even if the value changes, so no dependent keys
                }

                it("can check equality of different keys") {
                    let sut = SUT.comparison(lhs: .key(.init(value: "test1")), op: .isEqualTo, rhs: .key(.init(value: "test2")))
                    let context = Context.mockf()
                    context.store(answer: .int(0, match: []), forKey: "test1")
                    context.store(answer: .int(1, match: []), forKey: "test2")
                    let result = evaluate(predicate: sut, in: context)
                    expect(result) == .success(.init(value: false, keys: ["test1", "test2"]))
                    // this answer will be true even if the value changes, so no dependent keys
                }

                it("can compare a key to a value") {
                    let sut = SUT.comparison(lhs: .key(.init(value: "test")), op: .isEqualTo, rhs: .value(.int(0)))
                    let context = Context.mockf()
                    context.store(answer: .int(0, match: []), forKey: "test")
                    let result = evaluate(predicate: sut, in: context)
                    expect(result) == .success(.init(value: true, keys: ["test"]))
                }

                it("can compare a predicate to a key") {
                    let sut = SUT.comparison(lhs: .predicate(.true), op: .isEqualTo, rhs: .key(.init(value: "test")))
                    let context = Context.mockf()
                    context.store(answer: .bool(true, match: []), forKey: "test")
                    let result = evaluate(predicate: sut, in: context)
                    expect(result) == .success(.init(value: true, keys: ["test"]))
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
