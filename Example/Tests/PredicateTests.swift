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
import Foundation

@testable import Rules

class PredicateTests: QuickSpec {
    override func spec() {

        describe("Predicate") {

            describe("Encodable") {

                it("can encode .false") {
                    let sut = SUT.false
                    let expected: [AnyHashable: Any] = ["type": "false"]
                    switch jsonObject(for: sut) {
                    case .failed(let error): fail("\(error)")
                    case .success(let jsonObject):
                        expect(jsonObject == expected).to(beTrue())
                    }
                }

                it("can encode .true") {
                    let sut = SUT.true
                    let expected: [AnyHashable: Any] = ["type": "true"]
                    switch jsonObject(for: sut) {
                    case .failed(let error): fail("\(error)")
                    case .success(let jsonObject):
                        expect(jsonObject == expected).to(beTrue())
                    }
                }

                it("can encode .not(.true)") {
                    let sut = SUT.not(.true)
                    let expected: [AnyHashable: Any] = [
                        "type": "not",
                        "operand": ["type": "true"]
                    ]
                    switch jsonObject(for: sut) {
                    case .failed(let error): fail("\(error)")
                    case .success(let jsonObject):
                        expect(jsonObject == expected).to(beTrue())
                    }
                }

                it("can encode .comparison(lhs: .predicate(.true), op: .isEqualTo, rhs: .predicate(.true))") {
                    let sut = SUT.comparison(lhs: .predicate(.true), op: .isEqualTo, rhs: .predicate(.true))
                    let expected: [AnyHashable: Any] = [
                        "type": "comparison",
                        "lhs": ["predicate": ["type": "true"]],
                        "op": "isEqualTo",
                        "rhs": ["predicate": ["type": "true"]]
                    ]
                    switch jsonObject(for: sut) {
                    case .failed(let error): fail("\(error)")
                    case .success(let jsonObject):
                        expect(jsonObject == expected).to(beTrue())
                    }
                }

                context("encoding a custom ComparableAnswer type") {

                    it("can encode a predicate with a .comparable answer") {
                        let my = MyComparableType(x: 42)
                        let sut = SUT.comparison(lhs: .question("something"), op: .isLessThan, rhs: .answer(.comparable(my)))
                        let expected: [AnyHashable: Any] = [
                            "type": "comparison",
                            "lhs": ["question": "something"],
                            "op": "isLessThan",
                            "rhs": ["answer": ["comparableType": "MyComparableType", "comparable": [["x": 42]]]]
                        ]
                        switch jsonObject(for: sut) {
                        case .failed(let error): fail("\(error)")
                        case .success(let jsonObject):
                            expect(jsonObject == expected).to(beTrue())
                        }
                    }
                }

                context("encoding a custom EquatableAnswer type") {

                    it("can encode a predicate with a .equatable answer") {
                        let my = MyEquatableType(x: 42)
                        let sut = SUT.comparison(lhs: .question("something"), op: .isEqualTo, rhs: .answer(.equatable(my)))
                        let expected: [AnyHashable: Any] = [
                            "type": "comparison",
                            "lhs": ["question": "something"],
                            "op": "isEqualTo",
                            "rhs": ["answer": ["equatableType": "MyEquatableType", "equatable": [["x": 42]]]]
                        ]
                        switch jsonObject(for: sut) {
                        case .failed(let error): fail("\(error)")
                        case .success(let jsonObject):
                            expect(jsonObject == expected).to(beTrue())
                        }
                    }
                }
            }

            describe("Decodable") {

                it("can decode false") {
                    let sut = SUT.false
                    let result: Rules.Result<RulesEncodingError, RulesDecodingResult<Predicate>>
                        = data(for: sut).mapSuccess(decoded(from:))
                    switch result {
                    case .failed(let error): fail("\(error)")
                    case .success(.failed(let error)): fail("\(error)")
                    case .success(.success(let predicate)):
                        expect(predicate) == sut
                    }
                }

                it("can decode true") {
                    let sut = SUT.true
                    let result: Rules.Result<RulesEncodingError, RulesDecodingResult<Predicate>>
                        = data(for: sut).mapSuccess(decoded(from:))
                    switch result {
                    case .failed(let error): fail("\(error)")
                    case .success(.failed(let error)): fail("\(error)")
                    case .success(.success(let predicate)):
                        expect(predicate) == sut
                    }
                }

                it("can decode .comparison(lhs: .predicate(.true), op: .isEqualTo, rhs: .predicate(.true))") {
                    let sut = SUT.comparison(lhs: .predicate(.true), op: .isEqualTo, rhs: .predicate(.true))
                    let result: Rules.Result<RulesEncodingError, RulesDecodingResult<Predicate>>
                        = data(for: sut).mapSuccess(decoded(from:))
                    switch result {
                    case .failed(let error): fail("\(error)")
                    case .success(.failed(let error)): fail("\(error)")
                    case .success(.success(let predicate)):
                        expect(predicate) == sut
                    }
                }

                context("decoding a custom ComparableAnswer type") {

                    beforeEach {
                        Facts.Answer.register(comparableAnswerType: MyComparableType.self)
                    }

                    afterEach {
                        Facts.Answer.deregister(comparableAnswerType: MyComparableType.self)
                    }

                    it("can decode a predicate with a .comparable answer") {
                        let my = MyComparableType(x: 42)
                        let sut = SUT.comparison(lhs: .question("something"), op: .isLessThan, rhs: .answer(.comparable(my)))
                        let result: Rules.Result<RulesEncodingError, RulesDecodingResult<Predicate>>
                            = data(for: sut).mapSuccess(decoded(from:))
                        switch result {
                        case .failed(let error): fail("\(error)")
                        case .success(.failed(let error)): fail("\(error)")
                        case .success(.success(let predicate)):
                            expect(predicate) == sut
                        }
                    }
                }

                context("decoding a custom EquatableAnswer type") {

                    beforeEach {
                        Facts.Answer.register(equatableAnswerType: MyEquatableType.self)
                    }

                    afterEach {
                        Facts.Answer.deregister(equatableAnswerType: MyEquatableType.self)
                    }

                    it("can decode a predicate with a .equatable answer") {
                        let my = MyEquatableType(x: 42)
                        let sut = SUT.comparison(lhs: .question("something"), op: .isEqualTo, rhs: .answer(.equatable(my)))
                        let result: Rules.Result<RulesEncodingError, RulesDecodingResult<Predicate>>
                            = data(for: sut).mapSuccess(decoded(from:))
                        switch result {
                        case .failed(let error): fail("\(error)")
                        case .success(.failed(let error)): fail("\(error)")
                        case .success(.success(let predicate)):
                            expect(predicate) == sut
                        }
                    }
                }
            }

            describe("evaluation") {

                var falseNoKeys: SUT.EvaluationResult {
                    return .success(.init(value: false, dependencies: [], ambiguousRules: []))
                }

                var trueNoKeys: SUT.EvaluationResult {
                    return .success(.init(value: true, dependencies: [], ambiguousRules: []))
                }

                it("returns false for .false") {
                    let sut = SUT.false
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == falseNoKeys
                }

                it("returns true for .true") {
                    let sut = SUT.true
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == trueNoKeys
                }

                it("returns true for .not(.false)") {
                    let sut = SUT.not(.false)
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == trueNoKeys
                }

                it("returns false for .not(.true)") {
                    let sut = SUT.not(.true)
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == falseNoKeys
                }

                it("returns false for .and([.false, .false])") {
                    let sut = SUT.and([.false, .false])
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == falseNoKeys

                }

                it("returns false for .and([.false, .true])") {
                    let sut = SUT.and([.false, .true])
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == falseNoKeys

                }

                it("returns false for .and([.true, .false])") {
                    let sut = SUT.and([.true, .false])
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == falseNoKeys

                }

                it("returns true for .and([.true, .true])") {
                    let sut = SUT.and([.true, .true])
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == trueNoKeys

                }

                it("returns false for .or([.false, .false])") {
                    let sut = SUT.or([.false, .false])
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == falseNoKeys

                }

                it("returns true for .or([.false, .true])") {
                    let sut = SUT.or([.false, .true])
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == trueNoKeys

                }

                it("returns true for .or([.true, .false])") {
                    let sut = SUT.or([.true, .false])
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)

                    expect(result) == trueNoKeys

                }

                it("returns true for .or([.true, .true])") {
                    let sut = SUT.or([.true, .true])
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == trueNoKeys

                }

                it("can check equality of boolean predicates") {
                    let sut = SUT.comparison(lhs: .predicate(.false), op: .isEqualTo, rhs: .predicate(.false))
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == trueNoKeys
                }

                it("can check equality of int answers") {
                    let sut = SUT.comparison(lhs: .answer(.int(0)), op: .isEqualTo, rhs: .answer(.int(0)))
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == trueNoKeys
                }

                it("can check equality of double answers") {
                    let sut = SUT.comparison(lhs: .answer(.int(0)), op: .isEqualTo, rhs: .answer(.int(0)))
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == trueNoKeys
                }

                it("can check equality of string answers") {
                    let sut = SUT.comparison(lhs: .answer(.string("0")), op: .isEqualTo, rhs: .answer(.string("0")))
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == trueNoKeys
                }

                it("can compare int answers") {
                    let sut = SUT.comparison(lhs: .answer(.int(0)), op: .isLessThan, rhs: .answer(.int(1)))
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == trueNoKeys
                }

                it("can compare double answers") {
                    let sut = SUT.comparison(lhs: .answer(.int(0)), op: .isLessThan, rhs: .answer(.int(1)))
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == trueNoKeys
                }

                it("can compare string answers") {
                    let sut = SUT.comparison(lhs: .answer(.string("0")), op: .isLessThan, rhs: .answer(.string("1")))
                    var facts: Facts = .mockf()
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == trueNoKeys
                }

                it("can check equality of the same question") {
                    let sut = SUT.comparison(lhs: .question(.init(identifier: "test")), op: .isEqualTo, rhs: .question(.init(identifier: "test")))
                    var facts = Facts.mockf()
                    facts.know(answer: .int(0), forQuestion: "test")
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == .success(.init(value: true, dependencies: ["test"], ambiguousRules: []))
                }

                it("can check inequality of the same question") {
                    let sut = SUT.comparison(lhs: .question(.init(identifier: "test")), op: .isNotEqualTo, rhs: .question(.init(identifier: "test")))
                    var facts = Facts.mockf()
                    facts.know(answer: .int(0), forQuestion: "test")
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == .success(.init(value: false, dependencies: ["test"], ambiguousRules: []))
                }

                it("can check equality of different dependencies") {
                    let sut = SUT.comparison(lhs: .question(.init(identifier: "test1")), op: .isEqualTo, rhs: .question(.init(identifier: "test2")))
                    var facts = Facts.mockf()
                    facts.know(answer: .int(0), forQuestion: "test1")
                    facts.know(answer: .int(1), forQuestion: "test2")
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == .success(.init(value: false, dependencies: ["test1", "test2"], ambiguousRules: []))
                }

                it("can compare a question to an answer") {
                    let sut = SUT.comparison(lhs: .question(.init(identifier: "test")), op: .isEqualTo, rhs: .answer(.int(0)))
                    var facts = Facts.mockf()
                    facts.know(answer: .int(0), forQuestion: "test")
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == .success(.init(value: true, dependencies: ["test"], ambiguousRules: []))
                }

                it("can compare a predicate to a question") {
                    let sut = SUT.comparison(lhs: .predicate(.true), op: .isEqualTo, rhs: .question(.init(identifier: "test")))
                    var facts = Facts.mockf()
                    facts.know(answer: .bool(true), forQuestion: "test")
                    let result = evaluate(predicate: sut, given: &facts)
                    expect(result) == .success(.init(value: true, dependencies: ["test"], ambiguousRules: []))
                }
            }


            describe("parse(format:)") {
                it("replaces true with TRUEPREDICATE") {
                    let sut = " true    "
                    let result = parse(format: sut)
                    expect(result.predicateFormat) == "TRUEPREDICATE"
                }
            }

            describe("convert(ns:)") {

                it("can convert TRUEPREDICATE") {
                    let sut = "TRUEPREDICATE AND TRUEPREDICATE"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(.and([.true, .true]))
                }

                it("can convert TRUEPREDICATE AND TRUEPREDICATE") {
                    let sut = "TRUEPREDICATE AND TRUEPREDICATE"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(.and([.true, .true]))
                }

                it("can convert someQuestion == 'someAnswer' AND TRUEPREDICATE") {
                    let sut = "someQuestion == 'someAnswer' AND TRUEPREDICATE"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .and(
                            [
                                .comparison(
                                    lhs: .question(.init(identifier: "someQuestion")),
                                    op: .isEqualTo,
                                    rhs: .answer(.string("someAnswer"))
                                ),
                                .true
                            ]
                        )
                    )
                }

                it("can convert someQuestion == -42") {
                    let sut = "someQuestion == -42"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .question(.init(identifier: "someQuestion")),
                            op: .isEqualTo,
                            rhs: .answer(.int(-42))
                        )
                    )
                }

                it("can convert someQuestion == false") {
                    let sut = "someQuestion == false"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .question(.init(identifier: "someQuestion")),
                            op: .isEqualTo,
                            rhs: .predicate(.false)
                        )
                    )
                }

                it("can convert someQuestion == true") {
                    let sut = "someQuestion == true"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .question(.init(identifier: "someQuestion")),
                            op: .isEqualTo,
                            rhs: .predicate(.true)
                        )
                    )
                }

                it("can convert someQuestion == 2.5") {
                    let sut = "someQuestion == 2.5"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .question(.init(identifier: "someQuestion")),
                            op: .isEqualTo,
                            rhs: .answer(.double(2.5))
                        )
                    )
                }

                it("can convert 1.5 < 2.5") {
                    let sut = "1.5 < 2.5"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .answer(.double(1.5)),
                            op: .isLessThan,
                            rhs: .answer(.double(2.5))
                        )
                    )
                }
           }

        }
    }
}

enum RulesEncodingError: Error, Equatable {
    case dataEncodingFailed
    case stringEncodingFailed
    case JSONSerializationFailed
    case JSONSerializationTypeMismatch
}

typealias DataEncodingResult = Rules.Result<RulesEncodingError, Data>

func data<T: Encodable>(for encodable: T) -> DataEncodingResult {
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(encodable)
        return .success(data)
    } catch {
        return .failed(RulesEncodingError.dataEncodingFailed)
    }
}

typealias StringEncodingResult = Rules.Result<RulesEncodingError, String>

func string<T: Encodable>(for encodable: T) -> StringEncodingResult {
    switch data(for: encodable) {
    case .failed(let error):
        return .failed(error)
    case .success(let data):
        return String(data: data, encoding: .utf8)
            .map { .success($0) }
            ?? .failed(.stringEncodingFailed)
    }
}

typealias JSONObjectEncodingResult = Rules.Result<RulesEncodingError, [AnyHashable: Any]>

func jsonObject<T: Encodable>(for encodable: T) -> JSONObjectEncodingResult {
    switch data(for: encodable) {
    case .failed(let error):
        return .failed(error)
    case .success(let data):
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return (jsonObject as? [AnyHashable: Any])
                .map { .success($0) }
                ?? .failed(.JSONSerializationTypeMismatch)
        } catch {
            return .failed(.JSONSerializationFailed)
        }
    }
}

func == (left: [AnyHashable: Any], right: [AnyHashable: Any]) -> Bool {
    return NSDictionary(dictionary: left).isEqual(to: right)
}

enum RulesDecodingError: Error {
    case decodingError(DecodingError)
    case unknown
}

typealias RulesDecodingResult<T: Decodable> = Rules.Result<RulesDecodingError, T>

func decoded<T: Decodable>(from data: Data) -> RulesDecodingResult<T> {
    do {
        let decoder = JSONDecoder()
        return .success(try decoder.decode(T.self, from: data))
    } catch let decodingError as DecodingError {
        return .failed(.decodingError(decodingError))
    } catch {
        return .failed(.unknown)
    }
}

private struct MyComparableType: ComparableAnswer, Codable, Comparable {

    let x: Int

    init(x: Int) {
        self.x = x
    }

    // MARK: Equatable
    static func == (lhs: MyComparableType, rhs: MyComparableType) -> Bool {
        return lhs.x == rhs.x
    }

    // MARK: Comparable

    static func < (lhs: MyComparableType, rhs: MyComparableType) -> Bool {
        return lhs.x < rhs.x
    }

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case myType
        case x
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.x = try container.decode(Int.self, forKey: .x)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
    }

    // MARK: ComparableAnswer

    func isEqualTo(comparableAnswer: ComparableAnswer) -> Facts.Answer.ComparisonResult {
        return (comparableAnswer as? MyComparableType)
            .map { .success(self == $0) }
            ?? .failed(.typeMismatch)
    }

    func isLessThan(comparableAnswer: ComparableAnswer) -> Facts.Answer.ComparisonResult {
        return (comparableAnswer as? MyComparableType)
            .map { .success(self < $0) }
            ?? .failed(.typeMismatch)
    }

    static var comparableAnswerTypeName: String { return "MyComparableType" }

    public func encodeComparableAnswer(to encoder: Encoder, container: inout UnkeyedEncodingContainer) throws {
        try container.encode(self)
    }

    static func decodeComparableAnswer(from decoder: Decoder, container: inout UnkeyedDecodingContainer) throws -> ComparableAnswer {
        return try container.decode(MyComparableType.self)
    }

}

private struct MyEquatableType: EquatableAnswer, Codable, Equatable {

    let x: Int

    init(x: Int) {
        self.x = x
    }

    // MARK: Equatable
    static func == (lhs: MyEquatableType, rhs: MyEquatableType) -> Bool {
        return lhs.x == rhs.x
    }

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case myType
        case x
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.x = try container.decode(Int.self, forKey: .x)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
    }

    // MARK: EquatableAnswer

    func isEqualTo(equatableAnswer: EquatableAnswer) -> Facts.Answer.ComparisonResult {
        return (equatableAnswer as? MyEquatableType)
            .map { .success(self == $0) }
            ?? .failed(.typeMismatch)
    }

    static var equatableAnswerTypeName: String { return "MyEquatableType" }

    public func encodeEquatableAnswer(to encoder: Encoder, container: inout UnkeyedEncodingContainer) throws {
        try container.encode(self)
    }

    static func decodeEquatableAnswer(from decoder: Decoder, container: inout UnkeyedDecodingContainer) throws -> EquatableAnswer {
        return try container.decode(MyEquatableType.self)
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
