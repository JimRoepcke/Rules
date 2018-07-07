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
            }

            describe("Decodable") {

                it("can decode false") {
                    let sut = SUT.false
                    let result: Rules.Result<RulesEncodingError, RulesDecodingResult<Predicate>>
                        = data(for: sut).bimap(Rules.id, decoded(from:))
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
                        = data(for: sut).bimap(Rules.id, decoded(from:))
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
                        = data(for: sut).bimap(Rules.id, decoded(from:))
                    switch result {
                    case .failed(let error): fail("\(error)")
                    case .success(.failed(let error)): fail("\(error)")
                    case .success(.success(let predicate)):
                        expect(predicate) == sut
                    }
                }
            }

            describe("evaluation") {

                var falseNoKeys: SUT.EvaluationResult {
                    return .success(.init(value: false, dependencies: []))
                }

                var trueNoKeys: SUT.EvaluationResult {
                    return .success(.init(value: true, dependencies: []))
                }

                it("returns false for .false") {
                    let sut = SUT.false
                    let result = evaluate(predicate: sut, given: .mockf())
                    expect(result) == falseNoKeys
                }

                it("returns true for .true") {
                    let sut = SUT.true
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == trueNoKeys
                }

                it("returns true for .not(.false)") {
                    let sut = SUT.not(.false)
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == trueNoKeys
                }

                it("returns false for .not(.true)") {
                    let sut = SUT.not(.true)
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == falseNoKeys
                }

                it("returns false for .and([.false, .false])") {
                    let sut = SUT.and([.false, .false])
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == falseNoKeys

                }

                it("returns false for .and([.false, .true])") {
                    let sut = SUT.and([.false, .true])
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == falseNoKeys

                }

                it("returns false for .and([.true, .false])") {
                    let sut = SUT.and([.true, .false])
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == falseNoKeys

                }

                it("returns true for .and([.true, .true])") {
                    let sut = SUT.and([.true, .true])
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == trueNoKeys

                }

                it("returns false for .or([.false, .false])") {
                    let sut = SUT.or([.false, .false])
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == falseNoKeys

                }

                it("returns true for .or([.false, .true])") {
                    let sut = SUT.or([.false, .true])
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == trueNoKeys

                }

                it("returns true for .or([.true, .false])") {
                    let sut = SUT.or([.true, .false])
                    let result = evaluate(predicate: sut, given: .mockf())

                    expect(result) == trueNoKeys

                }

                it("returns true for .or([.true, .true])") {
                    let sut = SUT.or([.true, .true])
                    let result = evaluate(predicate: sut, given: .mockf())
                    expect(result) == trueNoKeys

                }

                it("can check equality of boolean values") {
                    let sut = SUT.comparison(lhs: .predicate(.false), op: .isEqualTo, rhs: .predicate(.false))
                    let result = evaluate(predicate: sut, given: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can check equality of int values") {
                    let sut = SUT.comparison(lhs: .value(.int(0)), op: .isEqualTo, rhs: .value(.int(0)))
                    let result = evaluate(predicate: sut, given: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can check equality of double values") {
                    let sut = SUT.comparison(lhs: .value(.double(0)), op: .isEqualTo, rhs: .value(.double(0)))
                    let result = evaluate(predicate: sut, given: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can check equality of string values") {
                    let sut = SUT.comparison(lhs: .value(.string("0")), op: .isEqualTo, rhs: .value(.string("0")))
                    let result = evaluate(predicate: sut, given: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can compare int values") {
                    let sut = SUT.comparison(lhs: .value(.int(0)), op: .isLessThan, rhs: .value(.int(1)))
                    let result = evaluate(predicate: sut, given: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can compare double values") {
                    let sut = SUT.comparison(lhs: .value(.double(0)), op: .isLessThan, rhs: .value(.double(1)))
                    let result = evaluate(predicate: sut, given: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can compare string values") {
                    let sut = SUT.comparison(lhs: .value(.string("0")), op: .isLessThan, rhs: .value(.string("1")))
                    let result = evaluate(predicate: sut, given: .mockf())
                    expect(result) == trueNoKeys
                }

                it("can check equality of the same key") {
                    let sut = SUT.comparison(lhs: .question(.init(identifier: "test")), op: .isEqualTo, rhs: .question(.init(identifier: "test")))
                    let facts = Facts.mockf()
                    facts.know(answer: .int(0), forQuestion: "test")
                    let result = evaluate(predicate: sut, given: facts)
                    expect(result) == .success(.init(value: true, dependencies: ["test"]))
                }

                it("can check inequality of the same key") {
                    let sut = SUT.comparison(lhs: .question(.init(identifier: "test")), op: .isNotEqualTo, rhs: .question(.init(identifier: "test")))
                    let facts = Facts.mockf()
                    facts.know(answer: .int(0), forQuestion: "test")
                    let result = evaluate(predicate: sut, given: facts)
                    expect(result) == .success(.init(value: false, dependencies: ["test"]))
                }

                it("can check equality of different dependencies") {
                    let sut = SUT.comparison(lhs: .question(.init(identifier: "test1")), op: .isEqualTo, rhs: .question(.init(identifier: "test2")))
                    let facts = Facts.mockf()
                    facts.know(answer: .int(0), forQuestion: "test1")
                    facts.know(answer: .int(1), forQuestion: "test2")
                    let result = evaluate(predicate: sut, given: facts)
                    expect(result) == .success(.init(value: false, dependencies: ["test1", "test2"]))
                }

                it("can compare a key to a value") {
                    let sut = SUT.comparison(lhs: .question(.init(identifier: "test")), op: .isEqualTo, rhs: .value(.int(0)))
                    let facts = Facts.mockf()
                    facts.know(answer: .int(0), forQuestion: "test")
                    let result = evaluate(predicate: sut, given: facts)
                    expect(result) == .success(.init(value: true, dependencies: ["test"]))
                }

                it("can compare a predicate to a key") {
                    let sut = SUT.comparison(lhs: .predicate(.true), op: .isEqualTo, rhs: .question(.init(identifier: "test")))
                    let facts = Facts.mockf()
                    facts.know(answer: .bool(true), forQuestion: "test")
                    let result = evaluate(predicate: sut, given: facts)
                    expect(result) == .success(.init(value: true, dependencies: ["test"]))
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

                it("can convert someKey == 'someValue' AND TRUEPREDICATE") {
                    let sut = "someKey == 'someValue' AND TRUEPREDICATE"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .and(
                            [
                                .comparison(
                                    lhs: .question(.init(identifier: "someKey")),
                                    op: .isEqualTo,
                                    rhs: .value(.string("someValue"))
                                ),
                                .true
                            ]
                        )
                    )
                }

                it("can convert someKey == -42") {
                    let sut = "someKey == -42"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .question(.init(identifier: "someKey")),
                            op: .isEqualTo,
                            rhs: .value(.int(-42))
                        )
                    )
                }

                it("can convert someKey == false") {
                    let sut = "someKey == false"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .question(.init(identifier: "someKey")),
                            op: .isEqualTo,
                            rhs: .predicate(.false)
                        )
                    )
                }

                it("can convert someKey == true") {
                    let sut = "someKey == true"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .question(.init(identifier: "someKey")),
                            op: .isEqualTo,
                            rhs: .predicate(.true)
                        )
                    )
                }

                it("can convert someKey == 2.5") {
                    let sut = "someKey == 2.5"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .question(.init(identifier: "someKey")),
                            op: .isEqualTo,
                            rhs: .value(.double(2.5))
                        )
                    )
                }

                it("can convert 1.5 < 2.5") {
                    let sut = "1.5 < 2.5"
                    let ns = parse(format: sut)
                    let predicate = convert(ns: ns)
                    expect(predicate) == .success(
                        .comparison(
                            lhs: .value(.double(1.5)),
                            op: .isLessThan,
                            rhs: .value(.double(2.5))
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
