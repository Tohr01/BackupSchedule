//
// Regex.swift
// BackupSchedule
//
// Created by Tohr01 on 20.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Foundation

func groups(for str: String, pattern: String, capture_group: [Int]?, regex_options: NSRegularExpression.Options = [.anchorsMatchLines]) -> [String]? {
    // Array containing the result of the regular expression. Has the following form: [0, 1, 2, ...] = [Match, CaptureGroup1, CaptureGroup2, ...]
    var result = [String]()
    do {
        let regex: NSRegularExpression = try NSRegularExpression(pattern: pattern, options: regex_options)
        let matches = regex.matches(in: str, range: NSRange(str.startIndex..., in: str))

        for match in matches {
            if let capture_group = capture_group {
                for capture_group in capture_group {
                    if match.numberOfRanges - 1 < capture_group {
                        print("Capture group out of range")
                        return nil
                    }
                    let range_bounds = match.range(at: capture_group)
                    guard let range = Range(range_bounds, in: str) else {
                        return nil
                    }
                    result.append(String(str[range]))
                }
                continue
            } else {
                result.append(contentsOf: (0 ..< match.numberOfRanges).map {
                    let range_bounds = match.range(at: $0)
                    guard let range = Range(range_bounds, in: str) else {
                        return ""
                    }
                    return String(str[range])
                })
            }
        }
    } catch {
        return nil
    }
    return result.isEmpty ? nil : result
}
