//
// DisableAutoBackup.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

class DisableAutoBackup: NSViewController {
    @IBAction func deactivateAB(_: Any) {
        if AppDelegate.tm.disableAutoBackup() != .success {
            let alert = NSAlert()
            alert.alertStyle = .warning
            var messageText: String
            if #available(macOS 13.0, *) {
                messageText = "Could not disable automatic backup... Please open the TimeMachine settings and change the 'Back up frequency' to 'Manually' under 'Options'."
            } else {
                messageText = "Could not disable automatic backup... Please open the TimeMachine settings and disable 'Back Up Automatically'."
            }
            alert.messageText = messageText
            alert.beginSheetModal(for: view.window!)
        }
        let autoBackupEnabled = AppDelegate.tm.isAutoBackupEnabled()
        if !autoBackupEnabled {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "disabledautobackup"), object: nil)
        }
    }
}
