//
// ReplacingSegue.swift
// BackupSchedule
//
// Created by Tohr01 on 26.09.24
// Copyright © 2024 Tohr01. All rights reserved.
//
        

import Cocoa

class ReplacingSegue: NSStoryboardSegue {
    override func perform() {
        if let sourceVC = sourceController as? NSViewController, let destVC = destinationController as? NSViewController {
            sourceVC.view.window?.contentViewController = destVC
        }
    }
}
