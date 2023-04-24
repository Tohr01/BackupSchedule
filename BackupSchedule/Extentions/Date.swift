//
// Date.swift
// BackupSchedule
//
// Created by Tohr01 on 24.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//


import Foundation

extension Optional where Wrapped == Date {
    func getLatestBackupString() -> String? {
        if let date = self {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        } else {
            return nil
        }
    }
}

extension Date {
    func getLatestBackupString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
