//
// DisableAutoBackup.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class DisableAutoBackup: NSViewController {
    @IBAction func deactivateAB(_ sender: Any) {
        _ = try? AppDelegate.tm?.disableAutoBackup()
        let autoBackupEnabled = AppDelegate.tm?.isAutoBackupEnabled()
        if let autoBackupEnabled = autoBackupEnabled, !autoBackupEnabled {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "disabledautobackup"), object: nil)
        }
    }
}
