//
//  Brain.swift
//  Rules
//  License: MIT, included below
//

/// A `Brain` can evaluate `Rule`s to infer answers to questions
/// that are not explicitly known in the collection of `Facts`.
///
/// Instances of `Brain` are **not** thread-safe.
public class Brain {

    public convenience init() {
        self.init(ambiguousCandidateRulesStrategy: .fail)
    }

    public init(ambiguousCandidateRulesStrategy: AmbiguousCandidateRulesStrategy) {
        self.rules = [:]
        self.ambiguousCandidateRulesStrategy = ambiguousCandidateRulesStrategy
    }

    public init(copying other: Brain) {
        self.rules = other.rules
        self.ambiguousCandidateRulesStrategy = other.ambiguousCandidateRulesStrategy
    }

    /// The `rules` used to infer answers to questions
    var rules: [Facts.Question: [Int: [Rule]]]

    /// Adds a rule to the `Brain`.
    /// This method is not thread-safe.
    public func add(rule: Rule) {
        // TODO: don't add the rule if it's already added - need the fingerprint for this
        rules[rule.question, default: [:]][rule.priority, default: []].append(rule)
    }

    typealias Candidate = (rule: Rule, dependencies: Predicate.Dependencies)

    func candidates(for question: Facts.Question, given facts: Facts) -> [Candidate] {
        var results: [Candidate] = []
        guard let rulesForKey = rules[question] else {
            return []
        }
        let priorities = rulesForKey.keys.sorted(by: >)
        for priority in priorities {
            guard let rules = rulesForKey[priority], !rules.isEmpty else {
                continue
            }
            // there are multiple candidate rules with the same priority
            // take the one(s) with the largest predicate size
            let rulesSortedBySize = rules.sorted { $0.predicate.size > $1.predicate.size }
            let maxSize = rulesSortedBySize.first?.predicate.size
            for rule in rulesSortedBySize {
                if rule.predicate.size == maxSize || results.isEmpty {
                    if let dependencies = rule.predicate.matches(given: facts) {
                        results.append((rule, dependencies))
                    }
                } else if !results.isEmpty {
                    break
                }
                // otherwise continue evaluating rules at this priority
            }
            // if any rules matched at this priority, the lower priority rules are ineligible
            if !results.isEmpty {
                break
            }
        }
        return results
    }

    public enum AmbiguousCandidateRulesStrategy: Equatable {
        /// When more than one candidate is found, fail to answer the question.
        case fail
        /// When more than one candidate is found, use one of them. The process
        /// to determine which to use is undefined and subject to change.
        case undefined
    }

    /// Defaults to `.fail`.
    public let ambiguousCandidateRulesStrategy: AmbiguousCandidateRulesStrategy

    typealias CandidateResult = Rules.Result<Facts.AnswerError, Candidate>

    func chooseRule(for question: Facts.Question, amongst candidateRules: [Candidate]) -> CandidateResult {
        if candidateRules.isEmpty {
            return .failed(.noRuleFound(question: question))
        } else if candidateRules.count > 1 {
            switch ambiguousCandidateRulesStrategy {
            case .fail:
                return .failed(.ambiguous(question: question))
            case .undefined:
                /// it would be nice to be able to somehow log a warning here
                return .success(candidateRules[0])
            }
        } else {
            return .success(candidateRules[0])
        }
    }

    /// only called when `facts` has no known or inferred answer for this question
    public func ask(question: Facts.Question, given facts: Facts) -> AnswerWithDependenciesResult {
        // find candidate rules
        let candidateRules = candidates(for: question, given: facts)
        let chosenCandidateResult = chooseRule(for: question, amongst: candidateRules)
        switch chosenCandidateResult {
        case .failed(let error):
            return .failed(error)
        case .success(let candidate):
            return candidate
                .rule
                .fire(given: facts, match: candidate.dependencies)
                .bimap(Facts.AnswerError.firingFailed, Rules.id)
        }
    }
}

public typealias AnswerWithDependenciesResult = Rules.Result<Facts.AnswerError, Facts.AnswerWithDependencies>

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
