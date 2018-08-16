//
//  main.swift
//  TextRulesToJSON
//
//  Created by Jim Roepcke on 2018-07-14.
//  Copyright © 2018 Jim Roepcke. All rights reserved.
//

import Foundation

func printToStdErr(_ s: String, preamble: String = "TextRulesToJSON: ") {
    FileHandle.standardError.write(.init(bytes: Array(preamble.utf8)))
    FileHandle.standardError.write(.init(bytes: Array(s.utf8)))
    FileHandle.standardError.write(.init(bytes: Array("\n".utf8)))
}

func dataOf(path: String) -> Rules.Result<Error, Data> {
    do {
        return .success(try Data(contentsOf: URL(fileURLWithPath: path)))
    } catch {
        return .failed(error)
    }
}

func contentsOf(path: String) -> Rules.Result<Error, String> {
    do {
        return .success(try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8))
    } catch {
        return .failed(error)
    }
}

enum ExitCode: Int32 {
    case success = 0
    case usage = 1
    case inputFileNotFound = 2
    case linterFileNotFound = 3
    case readingInputFileFailed = 4
    case readingLinterFileFailed = 5
    case decodingLinterFileFailed = 6
    case parsingFailed = 7
    case invalidRules = 8
    case encodingToJSONFailed = 9
}

struct Environment: Equatable {
    var input: String = ""
    var linterSpecification: LinterSpecification?
}

private var Current = Environment()

func configureEnvironment() -> ExitCode? {
    // Configure the `Current Environment`
    guard CommandLine.argc == 2 || CommandLine.argc == 3 else {
        printToStdErr("usage -- TextRulesToJSON <TextRulesPath> [<LinterSpecificationPath>]")
        return .usage
    }

    let inputPath = CommandLine.arguments[1]
    guard FileManager.default.fileExists(atPath: inputPath) else {
        printToStdErr("rules file not found: \(inputPath)")
        return .inputFileNotFound
    }

    switch contentsOf(path: inputPath) {
    case let .failed(error):
        printToStdErr("reading input failed: \(error)")
        return .readingInputFileFailed
    case let .success(contents):
        Current.input = contents
    }

    guard CommandLine.argc == 3 else {
        return nil
    }

    let lintPath = CommandLine.arguments[2]
    guard FileManager.default.fileExists(atPath: lintPath) else {
        printToStdErr("linter specification file not found: \(lintPath)")
        return .linterFileNotFound
    }

    switch dataOf(path: lintPath) {
    case let .failed(error):
        printToStdErr("reading linter specification file failed: \(error)")
        return .readingLinterFileFailed
    case let .success(data):
        let decoder = JSONDecoder()
        do {
            Current.linterSpecification = try decoder.decode(LinterSpecification.self, from: data)
            return nil
        } catch {
            printToStdErr("decoding linter specification file failed: \(error)")
            return .decodingLinterFileFailed
        }
    }
}

func convert() -> ExitCode {
    switch parse(humanRuleFileContents: Current.input) {
    case .failed(let errors):
        errors.forEach { printToStdErr("parsing input failed. line: \($0.line), rule: \($0.line), error: \($0.error)") }
        return .parsingFailed
    case .success(let values):
        let errors = linter(parsed: values, spec: Current.linterSpecification)
        guard errors.isEmpty else {
            errors
                .sorted { lhs, rhs in
                    switch (lhs.0?.lineNumber ?? 0, rhs.0?.lineNumber ?? 0) {
                    case let (l, r) where l < r: return true
                    case let (l, r) where l == r: return lhs.1 < rhs.1
                    default: return false
                    }
                }
                .forEach { printToStdErr(($0.0.map { "line \($0.lineNumber): " } ?? "") + "\($0.1)") }
            return .invalidRules
        }
        switch jsonData(rules: values.map { $0.rule }) {
        case let .failed(error):
            printToStdErr("encoding rules to JSON failed: \(error)")
            return .encodingToJSONFailed
        case let .success(data):
            FileHandle.standardOutput.write(data)
            return .success
        }
    }
}

func jsonData(rules: [Rule]) -> Rules.Result<Error, Data> {
    do {
        return .success(try JSONEncoder().encode(rules))
    } catch {
        return .failed(error)
    }
}

func main() -> ExitCode {
    return configureEnvironment()
        ?? convert()
}

exit(main().rawValue)
