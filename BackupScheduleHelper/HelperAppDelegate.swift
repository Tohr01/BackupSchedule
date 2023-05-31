//
// AppDelegate.swift
// BackupScheduleHelper
//
// Created by Tohr01 on 30.05.23
// Copyright © 2023 Tohr01. All rights reserved.
//


import Cocoa

@main
class HelperAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == "codes.cr.BackupSchedule"
        }
        
        if !isRunning {
            var path = Bundle.main.bundlePath as NSString
            for _ in 1...4 {
                path = path.deletingLastPathComponent as NSString
            }
            NSWorkspace.shared.launchApplication(path as String)
        }
    }
}

