//
//  Engine.swift
//  Rules
//  License: MIT, included below
//

public class Engine {

    public init() {
        self.rules = [:]
    }

    var rules: [Context.RHSKey: [Int: [Rule]]]

    public func add(rule: Rule) {
        // TODO: don't add the rule if it's already added - need the fingerprint for this
        rules[rule.key, default: [:]][rule.priority, default: []].append(rule)
    }

    typealias Candidate = (rule: Rule, match: Predicate.Match)

    func candidates(for key: Context.RHSKey, in context: Context) -> [Candidate] {
        var results: [Candidate] = []
        guard let rulesForKey = rules[key] else {
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
                    if let match = rule.predicate.matches(in: context) {
                        results.append((rule, match))
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

    /// only called when `context` has no stored or cached value for this key
    public func question(key: Context.RHSKey, in context: Context) -> QuestionWithMatchResult {
        // find candidate rules
        let candidateRules = candidates(for: key, in: context)
        if candidateRules.isEmpty {
            return .failed(.noRuleFound(key: key))
        } else if candidateRules.count > 1 {
            // TODO: consider not failing, just picking one
            // TODO: consider candidates(for:in:) preferring a non-ambiguous lower priority rule to an ambiguous rule
            return .failed(.ambiguous(key: key))
        } else {
            let candidateRule = candidateRules[0].rule
            return candidateRule
                .fire(in: context, match: candidateRules[0].match)
                .bimap(Context.AnswerError.firingFailed, Rules.id)
        }
    }
}

public typealias QuestionWithMatchResult = Rules.Result<Context.AnswerError, Context.Answer>

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
