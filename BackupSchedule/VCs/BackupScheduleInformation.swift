//
// BackupScheduleInformation.swift
// BackupSchedule
//
// Created by Tohr01 on 08.07.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class BackupScheduleInformation: NSViewController {    
    @IBAction func `continue`(_ sender: Any) {
        NotificationCenter.default.post(Notification(name: Notification.Name("informationVC")))
        UserDefaults.standard.set(true, forKey: "firstLaunch")
    }
}
