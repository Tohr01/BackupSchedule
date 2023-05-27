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
            return date.getLatestBackupString()
        } else {
            return nil
        }
    }
}

extension Date {
    func getLatestBackupString() -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(self) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "today at \(formatter.string(from: self))"
        } else if Calendar.current.isDateInTomorrow(self) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "tommorow at \(formatter.string(from: self))"
        }
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}