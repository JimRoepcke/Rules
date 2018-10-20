//
//  Brain.swift
//  Rules
//  License: MIT, included below
//

/// A `Brain` can evaluate `Rule`s to infer answers to questions
/// that are not explicitly known in the collection of `Facts`.
public struct Brain {

    public init() {
        self.rules = [:]
        self.assignments = [:]
        self.ambiguousRules = [:]
    }

    /// The `Rules` used to infer answers to questions
    /// When added, they are sorted by priority and predicate size.
    var rules: [Facts.Question: [Rule]]
    /// These pairs of were found to be ambiguous when added to the receiver
    var ambiguousRules: [Facts.Question: [(Rule, Rule)]]

    var assignments: [Assignment: AssignmentFunction]

    /// Adds a rule to the `Brain`.
    /// - returns: `true` if the there is no ambiguity in the rules, `false` otherwise.
    public mutating func add(rules rulesToAdd: [Rule]) {
        var questionsAdded: Set<Facts.Question> = []
        for rule in rulesToAdd {
            let question = rule.question
            questionsAdded.insert(question)
            rules[question, default: []].append(rule)
        }
        func markAmbiguous(rule1: Rule, rule2: Rule, `return` result: Bool) -> Bool {
            self.ambiguousRules[rule1.question, default: []].append((rule1, rule2))
            return result
        }
        for question in questionsAdded {
            rules[question]?.sort {
                $0.priority == $1.priority
                    ? ($0.predicate.size == $1.predicate.size
                        ? markAmbiguous(rule1: $0, rule2: $1, return: true) // sorts them as if $0 > $1
                        : $0.predicate.size > $1.predicate.size
                        )
                    : $0.priority > $1.priority
            }
        }
    }

    /// Adds an assignment function to the `Brain`.
    public mutating func add(assignment: Assignment, function: @escaping AssignmentFunction) {
        assignments[assignment] = function
    }

    typealias Candidate = (rule: Rule, dependencies: Facts.Dependencies)
    typealias CandidateResult = Rules.Result<Facts.AnswerError, Candidate>

    func candidate(for question: Facts.Question, given facts: inout Facts) -> CandidateResult {
        guard let rulesForQuestion = rules[question] else {
            return .failed(.noRuleFound(question: question))
        }
        for rule in rulesForQuestion {
            switch rule.predicate.matches(given: &facts) {
            case .failed(let error):
                return .failed(.candidateEvaluationFailed(error))
            case .success(let evaluation) where evaluation.value:
                return .success((rule, evaluation.dependencies))
            case .success:
                // nothing to do
                break // break the switch, not the loop!
            }
        }
        return .failed(.noRuleFound(question: question))
    }

    /// only called when `facts` has no known or inferred answer for this question
    public func ask(question: Facts.Question, given facts: inout Facts) -> Facts.AnswerWithDependenciesResult {
        // find candidate rules
        return candidate(for: question, given: &facts)
            .flatMapSuccess({
                answer(for: $0, given: facts)
                    .mapFailed(Facts.AnswerError.assignmentFailed)
            })
    }

    func answer(for candidate: Candidate, given facts: Facts) -> AssignmentResult {
        let rule = candidate.rule
        let dependencies = candidate.dependencies
        guard let assignment = rule.assignment else {
            return .success(.init(answer: rule.answer, dependencies: dependencies))
        }
        guard let assignmentFunction = assignments[assignment] else {
            return .failed(.assignmentNotFound(assignment: assignment))
        }
        return assignmentFunction(rule, facts, dependencies)
    }

    /// This is basically a `String`, but it's more type-safe.
    public struct Assignment: Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible, CustomDebugStringConvertible {
        public var identifier: String

        public typealias StringLiteralType = String

        public init(stringLiteral: String) {
            self.identifier = stringLiteral
        }

        public init(identifier: String) {
            self.identifier = identifier
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.identifier = try container.decode(String.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(identifier)
        }

        public var description: String { return identifier }
        public var debugDescription: String { return identifier }
    }

    /// If an `Assignment` cannot provide a `Facts.AnswerWithDependencies`, it
    /// returns one of these cases.
    public enum AssignmentError: Swift.Error, Equatable {
        case assignmentNotFound(assignment: Assignment)
        /// An unexpected error occurred.
        /// - parameter debugDescription: use for debug logging.
        case failed(debugDescription: String)
        /// The format of the RHS answer was incompatable with the expectations
        /// of the `assignment` function.
        case invalidAnswer(debugDescription: String, answer: String)
    }

    public typealias AssignmentResult
        = Rules.Result<AssignmentError, Facts.AnswerWithDependencies>

    public typealias AssignmentFunction
        = (Rule, Facts, Facts.Dependencies) -> AssignmentResult

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
