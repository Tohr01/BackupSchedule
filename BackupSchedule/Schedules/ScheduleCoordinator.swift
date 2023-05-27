//
// ScheduleCoordinator.swift
// BackupSchedule
//
// Created by Tohr01 on 11.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Foundation
import UserNotifications

class ScheduleCoordinator {
    public static var schedules: [BackupSchedule: Timer] = [:]

    public static var `default` = ScheduleCoordinator()

    func loadSchedules() {
        if let scheduleData = UserDefaults.standard.value(forKey: "schedules") as? [Data] {
            // Decode data
            var schedules: [BackupSchedule] = []
            for data in scheduleData {
                if let decodedSchedule = try? JSONDecoder().decode(BackupSchedule.self, from: data) {
                    schedules.append(decodedSchedule)
                }
            }
            for schedule in schedules {
                addToRunLoop(schedule)
            }
        }
    }

    deinit {
        // Invalidate timers
        _ = ScheduleCoordinator.schedules.values.map { $0.invalidate() }
        ScheduleCoordinator.schedules = [:]
    }

    func getNextExecutionDate() -> Date? {
        if let nextBackup = ScheduleCoordinator.schedules.values.sorted(by: { $0.fireDate.compare($1.fireDate) == .orderedAscending }).first {
            return nextBackup.fireDate
        }
        return nil
    }

    func addToRunLoop(_ schedule: BackupSchedule) {
        if let hour = schedule.timeActive.hour, let minute = schedule.timeActive.minute {
            let dateComponents = DateComponents(hour: hour, minute: minute)
            let date = Calendar.current.nextDate(after: Date(), matching: dateComponents, matchingPolicy: .nextTime)

            guard let date = date else {
                return
            }
            print(date.formatted(date: .abbreviated, time: .standard))
            let timer = Timer(fire: date, interval: 60 * 60 * 24, repeats: true) { _ in
                let currentDay = Calendar.current.component(.weekday, from: Date())
                let validRunDays = schedule.activeDays.map(\.rawValue.1)
                // Check if schedule should run today
                if validRunDays.contains(currentDay) {
                    let highLoad = SystemInformation.isUnderHighLoad()
                    let notification = UNMutableNotificationContent()
                    var shouldRun = true
                    if schedule.settings.disableWhenBattery, SystemInformation.isInBatteryMode() {
                        notification.title = "Backup will not run."
                        notification.subtitle = "Your Mac currently is in battery mode."
                        shouldRun = false
                    } else if schedule.settings.runWhenUnderHighLoad, highLoad {
                        notification.title = "Backup will not run."
                        notification.subtitle = "Your Mac is currently under high load."
                        shouldRun = false
                    }
                    if shouldRun {
                        notification.title = "Started Backup"
                        notification.subtitle = ""
                        try? AppDelegate.tm!.startBackup(destID: schedule.selectedDrive?.id)
                    }
                    if schedule.settings.startNotification {
                        let request = UNNotificationRequest(identifier: "backupNotification", content: notification, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }
            ScheduleCoordinator.schedules[schedule] = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func removeScheduleFromRunLoop(id: UUID) {
        _ = ScheduleCoordinator.schedules.filter { $0.key.id == id }.map { $0.value.invalidate() }
        ScheduleCoordinator.schedules = ScheduleCoordinator.schedules.filter { !($0.key.id == id) }
    }
}
