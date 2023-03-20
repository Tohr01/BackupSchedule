//
// ScheduleConfiguration.swift
// BackupSchedule
//
// Created by Tohr01 on 19.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

struct BackupSchedule {
    
}

class ScheduleConfiguration: NSViewController {

    @IBOutlet weak var destNameLabel: NSTextField!
    @IBOutlet weak var destCountMoreLabel: NSTextField!
    @IBOutlet weak var lastBackupLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        configureSidebar()
    }
    
}

// MARK: -
// MARK: Configure view on startup
extension ScheduleConfiguration {
    // SIDEBAR
    
    func configureSidebar() {
        configureDiskNames()
    }
    
    func configureDiskNames() {
        destNameLabel.stringValue = (try? AppDelegate.tm?.getPrimaryVolumeName()) ?? "# Error #"
        var volumeCount = (try? AppDelegate.tm?.getBackupVolumeCount()) ?? 1
        volumeCount -= 1;
        
        if volumeCount == 0 {
            destCountMoreLabel.isHidden = true
        } else {
            destCountMoreLabel.stringValue = "\(volumeCount) more"
        }
        if let latestBackup = AppDelegate.tm?.getLatestBackup() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            lastBackupLabel.stringValue = "Last backup on \(formatter.string(from: latestBackup))"
        }
    }
}

// MARK: -
// MARK: Errors
extension ScheduleConfiguration {
    
}

