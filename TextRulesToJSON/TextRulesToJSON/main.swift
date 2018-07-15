//
//  main.swift
//  TextRulesToJSON
//
//  Created by Jim Roepcke on 2018-07-14.
//  Copyright © 2018 Jim Roepcke. All rights reserved.
//

import Foundation

func main(argc: Int32, argv: [String]) -> Int32 {
    guard argc == 2 else {
        print("TextRulesToJSON: usage -- TextRulesToJSON <TextRulesPath>")
        return 1
    }
    let inputPath = argv[1]
    guard FileManager.default.fileExists(atPath: inputPath) else {
        print("TextRulesToJSON: file not found: \(inputPath)")
        return 2
    }
    var result: Int32 = 0
    var message = ""
    do {
        result = 3
        message = "reading input failed"
        let contents = try String(contentsOf: URL(fileURLWithPath: inputPath), encoding: .utf8)
        let parsingResult = parse(humanRuleFileContents: contents)
        switch parsingResult {
        case .failed(let errors):
            for error in errors {
                print("TextRulesToJSON: \(error)")
            }
            result = 0
        case .success(let rules):
            result = 4
            message = "encoding rules failed"
            let data = try JSONEncoder().encode(rules)
            result = 0
            message = ""
            guard let string = String.init(data: data, encoding: .utf8) else {
                print("TextRulesToJSON: could not encode JSON data as UTF8 string")
                return 5
            }
            print(string)
        }
    } catch let error {
        print("TextRulesToJSON: \(message): \(error)")
    }
    return result
}

exit(main(argc: CommandLine.argc, argv: CommandLine.arguments))
