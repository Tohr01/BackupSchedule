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
    static func constructDate(from weekday: Int, hour: Int, minute: Int) -> Date {
        let nextExecDateComps = DateComponents(hour: hour, minute: minute, weekday: weekday)
        let nextExecDate = Calendar.current.nextDate(after: Date.now, matching: nextExecDateComps, matchingPolicy: .nextTime)
        return nextExecDate!
    }

    func getLatestBackupString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        if Calendar.current.isDateInToday(self) {
            return "today at \(formatter.string(from: self))"
        } else if Calendar.current.isDateInTomorrow(self) {
            return "tommorow at \(formatter.string(from: self))"
        } else if Calendar.current.isDateInYesterday(self) {
            return "yesterday at \(formatter.string(from: self))"
        }
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    func isBetween(startDate: Date, endDate: Date) -> Bool {
        startDate <= self && self <= endDate
    }
}
