//
// ScheduleSelectionIndicator.swift
// BackupSchedule
//
// Created by Tohr01 on 30.08.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

class ScheduleSelectionIndicator: NSImageView {
    func moveToY(_ y: CGFloat) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            self.animator().frame.origin.y = y
        }
    }
}
