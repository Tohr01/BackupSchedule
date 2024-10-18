//
// Schedule.swift
// BackupSchedule
//
// Created by Tohr01 on 06.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Foundation

struct BackupSchedule: Codable, Hashable {
    static func == (lhs: BackupSchedule, rhs: BackupSchedule) -> Bool {
        lhs.id == rhs.id && lhs.displayName == rhs.displayName && lhs.activeDays == rhs.activeDays && lhs.timeActive == rhs.timeActive && lhs.selectedDrive == rhs.selectedDrive && lhs.settings == rhs.settings
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        hasher.combine(activeDays)
        hasher.combine(timeActive)
        hasher.combine(selectedDrive)
        hasher.combine(settings)
    }

    func getNextExecDate(after date: Date = Date.now) -> Date? {
        var validDays = activeDays.map(\.rawValue.1).sorted()
        let cal = Calendar.current
        let dateComps = cal.dateComponents([.weekday, .hour, .minute], from: date)
        let currentWeekday = dateComps.weekday!
        if validDays.contains(currentWeekday) {
            // Run day is today
            // Check if run time has passed
            let currentHour = dateComps.hour!
            let currentMinute = dateComps.minute!
            // Time active e.g. 11:20 currentTime e.g. 10:56
            if currentHour < timeActive.hour! || (currentHour == timeActive.hour! && currentMinute <= timeActive.minute!) {
                // Backup is upcoming today
                var nextExecDateComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .weekday], from: Date.now)
                nextExecDateComps.hour = timeActive.hour!
                nextExecDateComps.minute = timeActive.minute!
                return cal.date(from: nextExecDateComps)!
            } else {
                // Time has passed
                if let currentWeekdayIdx = validDays.firstIndex(where: { $0 == currentWeekday }) {
                    let nextWeekdayIdx = (currentWeekdayIdx + 1) % validDays.count
                    return Date.constructDate(from: validDays.sorted()[nextWeekdayIdx], hour: timeActive.hour!, minute: timeActive.minute!)
                }
            }
        } else {
            if currentWeekday < validDays.sorted()[validDays.count - 1] {
                return Date.constructDate(from: validDays.sorted()[0], hour: timeActive.hour!, minute: timeActive.minute!)
            } else {
                validDays.append(currentWeekday)
                let nextWeekdayIdx = validDays.sorted().firstIndex(of: currentWeekday)! + 1
                let nextWeekday = validDays[nextWeekdayIdx % validDays.count]
                return Date.constructDate(from: nextWeekday, hour: timeActive.hour!, minute: timeActive.minute!)
            }
        }
        return nil
    }

    func getTimeString() -> String {
        let time = timeActive
        if let hour = time.hour, let minute = time.minute {
            return "\(hour < 10 ? "0\(hour)" : String(hour)):\(minute < 10 ? "0\(minute)" : String(minute))"
        }
        return "00:00"
    }

    func getHourString() -> String {
        let time = timeActive
        if let hour = time.hour {
            return "\(hour < 10 ? "0\(hour)" : String(hour))"
        }
        return "00"
    }

    func getMinuteString() -> String {
        let time = timeActive
        if let minute = time.minute {
            return "\(minute < 10 ? "0\(minute)" : String(minute))"
        }
        return "00"
    }

    var id: UUID = .init()
    var displayName: String
    var activeDays: [ActiveDays]
    var timeActive: DateComponents
    var selectedDrive: TMDestination?
    var settings: BackupScheduleSettings
}

enum ActiveDays: Codable, RawRepresentable {
    typealias RawValue = (String, Int)

    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var rawValue: (String, Int) {
        switch self {
        case .monday:
            return ("monday", 2)
        case .tuesday:
            return ("tuesday", 3)
        case .wednesday:
            return ("wednesday", 4)
        case .thursday:
            return ("thursday", 5)
        case .friday:
            return ("friday", 6)
        case .saturday:
            return ("saturday", 7)
        case .sunday:
            return ("sunday", 1)
        }
    }

    init?(rawValue: (String, Int)) {
        switch rawValue {
        case ("monday", 2):
            self = .monday
        case ("tuesday", 3):
            self = .tuesday
        case("wednesday", 4):
            self = .wednesday
        case ("thursday", 5):
            self = .thursday
        case ("friday", 6):
            self = .friday
        case ("saturday", 7):
            self = .saturday
        case ("sunday", 1):
            self = .sunday
        default:
            return nil
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "monday":
            self = .monday
        case "tuesday":
            self = .tuesday
        case"wednesday":
            self = .wednesday
        case "thursday":
            self = .thursday
        case "friday":
            self = .friday
        case "saturday":
            self = .saturday
        case "sunday":
            self = .sunday
        default:
            return nil
        }
    }
}

struct BackupScheduleSettings: Codable, Equatable, Hashable {
    var startNotification: Bool
    var disableWhenBattery: Bool
    var runWhenUnderHighLoad: Bool
}
