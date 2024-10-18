//
// BackupWindow.swift
// BackupSchedule
//
// Created by Tohr01 on 30.05.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

class BackupWindow: NSWindow {
    override func mouseDown(with event: NSEvent) {
        if event.type == .leftMouseDown {
            endEditing(for: nil)
            super.mouseDown(with: event)
        }
    }
}
