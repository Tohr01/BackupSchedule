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
        return lhs.id == rhs.id && lhs.displayName == rhs.displayName && lhs.activeDays == rhs.activeDays && lhs.timeActive == rhs.timeActive && lhs.selectedDrive == rhs.selectedDrive && lhs.settings == rhs.settings
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        hasher.combine(activeDays)
        hasher.combine(timeActive)
        hasher.combine(selectedDrive)
        hasher.combine(settings)
    }
    
    var id: UUID = UUID()
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
            break
        case ("tuesday", 3):
            self = .tuesday
            break
        case("wednesday", 4):
            self = .wednesday
            break
        case ("thursday", 5):
            self = .thursday
            break
        case ("friday", 6):
            self = .friday
            break
        case ("saturday", 7):
            self = .saturday
            break
        case ("sunday", 1):
            self = .sunday
            break
        default:
            return nil
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "monday":
            self = .monday
            break
        case "tuesday":
            self = .tuesday
            break
        case"wednesday":
            self = .wednesday
            break
        case "thursday":
            self = .thursday
            break
        case "friday":
            self = .friday
            break
        case "saturday":
            self = .saturday
            break
        case "sunday":
            self = .sunday
            break
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
