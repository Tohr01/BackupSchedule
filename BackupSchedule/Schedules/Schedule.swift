//
// Schedule.swift
// BackupSchedule
//
// Created by Tohr01 on 06.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Foundation

struct BackupSchedule {
    var id: UUID = UUID()
    var displayName: String
    var activeDays: ActiveDays
    var timeActive: DateComponents
    var selectedDrive: TMDestination?
    var settings: BackupScheduleSettings
}

struct ActiveDays {
    var monday: Bool = false
    var tuesday: Bool = false
    var wednesday: Bool = false
    var thursday: Bool = false
    var friday: Bool = false
    var saturday: Bool = false
    var sunday: Bool = false
}


struct BackupScheduleSettings {
    var startNotification: Bool
    var disableWhenBattery: Bool
    var runWhenUnderHighLoad: Bool
}
