//
//  Linting.swift
//  Rules
//  License: MIT, included below
//

enum AnswerConstraint: Equatable {
    case strings([String])
    case string
    case bool
    case int
    case double
    case any
}

extension AnswerConstraint: Decodable {
    enum AnswerConstraintDecodingError: String, Error {
        case unexpectedValue
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .strings(try container.decode([String].self))
        } catch {
            switch try container.decode(String.self) {
            case "string": self = .string
            case "bool": self = .bool
            case "int": self = .int
            case "double": self = .double
            case "any": self = .any
            default:
                throw AnswerConstraintDecodingError.unexpectedValue
            }
        }
    }
}

struct LinterSpecification: Equatable, Decodable {
    let lhs: [String: AnswerConstraint]
    let rhs: [String: AnswerConstraint]
}

typealias RuleLint = (ParsedHumanRule?, String)

func linter(parsed values: [ParsedHumanRule], spec: LinterSpecification?) -> [RuleLint] {
    return checkDuplicates(parsed: values)
        + checkPredicates(parsed: values)
        + (spec.map { checkSpecification(parsed: values, spec: $0) } ?? [])
}

func checkDuplicates(parsed values: [ParsedHumanRule]) -> [RuleLint] {
    return values.reduce((rules: Set<String>(), errors: [RuleLint]()), { result, value in
        (
            result.rules.union([value.line]),
            result.errors + (result.rules.contains(value.line) ? [(value, "duplicate rule found")] : [])
        )
    }).errors
}

func checkPredicates(parsed values: [ParsedHumanRule]) -> [RuleLint] {
    func isValid(predicate: Predicate) -> String? {
        // these cases correspond to the cases of `evaluate(predicate:given:)` that
        // immediately return `.failed`.
        switch predicate {
        case .comparison(.predicate, .isLessThan, _),
             .comparison(.predicate, .isGreaterThan, _),
             .comparison(.predicate, .isGreaterThanOrEqualTo, _),
             .comparison(.predicate, .isLessThanOrEqualTo, _),
             .comparison(_, .isLessThan, .predicate),
             .comparison(_, .isGreaterThan, .predicate),
             .comparison(_, .isGreaterThanOrEqualTo, .predicate),
             .comparison(_, .isLessThanOrEqualTo, .predicate):
            return "invalid predicate: boolean values are not comparable"
        case .comparison(.predicate, _, .answer),
             .comparison(.answer, _, .predicate):
            return "invalid predicate: type mismatch"
        default:
            return nil
        }
    }
    return values
        .map { p in isValid(predicate: p.rule.predicate).map { (.some(p), "\($0)") } }
        .compactMap(Rules.id)
}

func checkSpecification(parsed values: [ParsedHumanRule], spec: LinterSpecification) -> [RuleLint] {
    return [
        checkAllRHSQuestionsAreValid,
        checkFallbackRulesExist,
        checkRHSAnswerTypeIsCorrect,
        checkLHSAnswerTypesAreCorrect
        ]
        .flatMap { $0(values, spec) }
}

func checkAllRHSQuestionsAreValid(parsed values: [ParsedHumanRule], spec: LinterSpecification) -> [RuleLint] {
    let questions = Set(spec.rhs.keys)
    func check(value: ParsedHumanRule) -> RuleLint? {
        return questions.contains(value.rule.question.identifier)
            ? nil
            : (.init(value), "rhs question \(value.rule.question.identifier) not found in the linter file")
    }
    return values
        .map(check)
        .compactMap(Rules.id)
}

func checkFallbackRulesExist(parsed values: [ParsedHumanRule], spec: LinterSpecification) -> [RuleLint] {
    func hasFallbackRule(rhs: String) -> RuleLint? {
        return values.contains { $0.rule.question.identifier == rhs && $0.rule.predicate == .true && $0.rule.priority == 0 }
            ? nil
            : (nil, "no fallback rule found for \(rhs)")
    }
    return spec.rhs.keys
        .map(hasFallbackRule)
        .compactMap(Rules.id)
}

func checkRHSAnswerTypeIsCorrect(parsed values: [ParsedHumanRule], spec: LinterSpecification) -> [RuleLint] {
    func constraint(_ pair: (key: String, value: AnswerConstraint), matches value: ParsedHumanRule) -> RuleLint? {
        guard value.rule.question.identifier == pair.key else {
            return nil
        }
        let rule = value.rule
        switch pair.value {
        case .any:
            return nil
        case .strings(let strings):
            return strings.contains(rule.answer)
                ? nil
                : (.init(value), "the answer for \(rule.question.identifier) rules must be one of: \(strings.joined(separator: ", "))")
        case .string:
            return rule.assignment.map { (value, "rule with question \(rule.question.identifier) expected to have a string answer, but it has an assignment specified: \($0). Remove the assignment to use the default assignment which results in a string answer") }
        case .bool,
             .int,
             .double:
            return (value, "constraining rule with question \(rule.question.identifier) to non-string answers is not currently supported because parsing assignments from human rule files has not been implemented yet")
        }
    }
    func hasCorrectRHSAnswerType(pair: (key: String, value: AnswerConstraint)) -> [RuleLint] {
        return values
            .compactMap { constraint(pair, matches: $0) }
    }
    return spec.rhs
        .flatMap(hasCorrectRHSAnswerType)
        .compactMap(Rules.id)
}

func checkLHSAnswerTypesAreCorrect(parsed values: [ParsedHumanRule], spec: LinterSpecification) -> [RuleLint] {
    func typeName<T>(of x: T) -> String {
        return String(describing: type(of: x)).lowercased()
    }
    func checkConstraint(for question: Facts.Question, and answer: Facts.Answer, value: ParsedHumanRule) -> [RuleLint] {
        guard let constraint = spec.lhs[question.identifier] else {
            return [(value, "lhs question \(question) not found in the linter file")]
        }
        switch (constraint, answer.value) {
        case (.any, _),
             (.int, is Int),
             (.double, is Double),
             (.string, is String): return []
        case (.bool, let x): return [(value, "type mismatch, \(question) should be compared to a bool, not a \(typeName(of: x))")]
        case (.int, let x): return [(value, "type mismatch, \(question) should be compared to an int, not a \(typeName(of: x))")]
        case (.double, let x): return [(value, "type mismatch, \(question) should be compared to a double, not a \(typeName(of: x))")]
        case (.string, let x): return [(value, "type mismatch, \(question) should be compared to a string, not a \(typeName(of: x))")]
        case (.strings(let strings), let x as String) where strings.contains(x): return []
        case (.strings(let strings), is String): return [(value, "\(question) may only be compared to one of: \(strings.joined(separator: ", "))")]
        case (.strings, let x): return [(value, "type mismatch, \(question) should be compared to a string, not a \(typeName(of: x))")]
        }
    }
    func check(predicate: Predicate, value: ParsedHumanRule) -> [RuleLint] {
        switch predicate {
        case .false, .true: return []
        case .not(let p):
            return check(predicate: p, value: value)
        case .and(let ps), .or(let ps):
            return ps.flatMap { check(predicate: $0, value: value) }
        case .comparison(.predicate(let left), _, .predicate(let right)):
            return check(predicate: left, value: value)
                + check(predicate: right, value: value)
        case .comparison(.question(let question), _, .predicate(let p)),
             .comparison(.predicate(let p), _, .question(let question)):
            let ps = check(predicate: p, value: value)
            guard let constraint = spec.lhs[question.identifier] else {
                return ps + [(value, "lhs question \(question) not found in the linter file")]
            }
            switch constraint {
            case .any, .bool: return ps
            case .int:
                return ps + [(value, "type mismatch, \(question) should be an int but it is being compared to a bool")]
            case .double:
                return ps + [(value, "type mismatch, \(question) should be a double but it is being compared to a bool")]
            case .string, .strings:
                return ps + [(value, "type mismatch, \(question) should be a string but it is being compared to a bool")]
            }
        case .comparison(.answer(let answer), _, .predicate) where answer.value is Bool:
            return []
        case .comparison(.answer(let answer), _, .predicate):
            return [(value, "type mismatch, comparing a \(typeName(of: answer.value)) to a bool")]
        case .comparison(.predicate, _, .answer(let answer)) where answer.value is Bool:
            return []
        case .comparison(.predicate, _, .answer(let answer)):
            return [(value, "type mismatch, comparing a \(typeName(of: answer.value)) to a bool")]
        case .comparison(.question(let question), _, .answer(let answer)):
            return checkConstraint(for: question, and: answer, value: value)
        case .comparison(.answer(let answer), _, .question(let question)):
            return checkConstraint(for: question, and: answer, value: value)
        case .comparison(.question, _, .question):
            return [] // not yet implemented
        case .comparison(.answer(let left), _, .answer(let right)) where type(of: left.value) == type(of: right.value):
            // it could be argued this shouldn't be allowed because it's silly
            // 8 == 8, 8 == 4, 8 < 4, 8 > 4, these are all constants and
            // should not be a part of a rules file
            return []
        case .comparison(.answer(let left), _, .answer(let right)):
            return [(value, "type mismatch, comparing a \(typeName(of: left.value)) to a \(typeName(of: right.value))")]
        }
    }
    func checkLHS(value: ParsedHumanRule) -> [RuleLint] {
        return check(predicate: value.rule.predicate, value: value)
    }
    return values
        .flatMap(checkLHS)
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
