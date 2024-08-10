//
// Window.swift
// BackupSchedule
//
// Created by Tohr01 on 07.08.24
// Copyright © 2024 Tohr01. All rights reserved.
//
        

import Cocoa

extension NSWindow {
    func defaultAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.beginSheetModal(for: self)
    }
}
