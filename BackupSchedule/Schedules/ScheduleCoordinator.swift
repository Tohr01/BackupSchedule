//
// ScheduleCoordinator.swift
// BackupSchedule
//
// Created by Tohr01 on 11.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Foundation

class ScheduleCoordinator {
    public static var schedules: [BackupSchedule : Timer] = [:]
    
    public static var `default` = ScheduleCoordinator()
    
    deinit {
        // Invalidate timers
        _ = ScheduleCoordinator.schedules.values.map{$0.invalidate()}
        ScheduleCoordinator.schedules = [:]
    }
    
    func addToRunLoop(_ schedule: BackupSchedule) {
        if let hour = schedule.timeActive.hour, let minute = schedule.timeActive.minute {
            let dateComponents = DateComponents(hour: hour, minute: minute)
            let date = Calendar.current.nextDate(after: Date(), matching: dateComponents, matchingPolicy: .nextTime)
            #warning("fix wrong date calc")
            guard let date = date else {
                return
            }
            print(date)
            var timer = Timer(fire: date, interval: 60*60*24, repeats: true) { timer in
                let currentDay = Calendar.current.component(.weekday, from: Date())
                let validRunDays = schedule.activeDays.map({$0.rawValue.1})
                if validRunDays.contains(currentDay) {
                    print("RUN")
                }
            }
            ScheduleCoordinator.schedules[schedule] = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}
