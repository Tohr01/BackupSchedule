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
    
    public static var schedules: [(BackupSchedule, Timer)] = []
    public static var `default` = ScheduleCoordinator()
    
    private var sleepStart: Date? = nil
    
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
        _ = ScheduleCoordinator.schedules.map { $0.1.invalidate() }
        ScheduleCoordinator.schedules = []
    }
    
    func getNextExecutionDate() -> Date? {
        print(ScheduleCoordinator.schedules.compactMap({$0.0.getNextExecDate()}))
        if let nextBackup = ScheduleCoordinator.schedules.compactMap({$0.0.getNextExecDate()}).sorted().first {
            return nextBackup
        }
        return nil
    }
    
    
    func addToRunLoop(_ schedule: BackupSchedule) {
        if let timer = getTimer(for: schedule) {
            ScheduleCoordinator.schedules.append((schedule, timer))
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    
    func getTimer(for schedule: BackupSchedule) -> Timer? {
        if let hour = schedule.timeActive.hour, let minute = schedule.timeActive.minute {
            let dateComponents = DateComponents(hour: hour, minute: minute)
            let date = Calendar.current.nextDate(after: Date(), matching: dateComponents, matchingPolicy: .nextTime)
            
            guard let date = date else {
                return nil
            }
            
            let timer = Timer(fire: date, interval: 60 * 60 * 24, repeats: true) { _ in
                let currentDay = Calendar.current.component(.weekday, from: Date())
                let validRunDays = schedule.activeDays.map(\.rawValue.1)
                // Check if schedule should run today
                if validRunDays.contains(currentDay) {
                    let highLoad = SystemInformation.isUnderHighLoad()
                    let notification = UNMutableNotificationContent()
                    var shouldRun = true
                    if schedule.settings.disableWhenBattery, SystemInformation.isInBatteryMode() {
                        notification.title = "Backup will not run"
                        notification.subtitle = "Your Mac currently is in battery mode."
                        shouldRun = false
                    } else if schedule.settings.runWhenUnderHighLoad, highLoad {
                        notification.title = "Backup will not run"
                        notification.subtitle = "Your Mac is currently under high load."
                        shouldRun = false
                    }
                    if !AppDelegate.tm!.isMounted(destination: schedule.selectedDrive) {
                        notification.title = "Backup will not run"
                        notification.subtitle = "Backup drive not connected."
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
            return timer
        }
        return nil
    }
    
    
    func removeScheduleFromRunLoop(id: UUID) {
        _ = ScheduleCoordinator.schedules.filter { $0.0.id == id }.map { $0.1.invalidate() }
        ScheduleCoordinator.schedules = ScheduleCoordinator.schedules.filter { !($0.0.id == id) }
    }
    
    func replaceSchedule(_ schedule: BackupSchedule) {
        if let timer = getTimer(for: schedule), let oldScheduleIdx = ScheduleCoordinator.schedules.firstIndex(where: {$0.0.id == schedule.id}) {
            _ = ScheduleCoordinator.schedules.filter { $0.0.id == schedule.id }.map { $0.1.invalidate() }
            ScheduleCoordinator.schedules[oldScheduleIdx] = (schedule, timer)
        }
    }
    
    @objc func macWillGoToSleep(_ aNotification: Notification) {
        sleepStart = Date.now
    }
    
    @objc func macWillWakeUp(_ aNotification: Notification) {
        if let sleepStartDate = sleepStart {
            // Get schedules that where missed when mac slept
            if !ScheduleCoordinator.schedules.compactMap({$0.0.getNextExecDate(after: sleepStartDate)}).filter({$0.compare(Date.now) == .orderedAscending}).isEmpty {
                let notificationCenter = UNUserNotificationCenter.current()
                let content = UNMutableNotificationContent()
                content.title = "Starting Backup"
                content.subtitle = "Running Backups missed when Mac was sleeping."
                let request = UNNotificationRequest(identifier: "backupNotification", content: content, trigger: nil)
                notificationCenter.add(request)
            }
        }
    }
}
