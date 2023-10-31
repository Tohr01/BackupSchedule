//
// Settings.swift
// BackupSchedule
//
// Created by Tohr01 on 30.10.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class Settings: NSViewController {

    @IBOutlet weak var autoBackupButton: DefaultButton!
    @IBOutlet weak var autoBackupLabel1: NSTextField!
    @IBOutlet weak var autoBackupLabel2: NSTextField!
    
    @IBOutlet weak var deleteSnapshotButton: DefaultButton!
    @IBOutlet weak var deleteSnapshotLabel1: NSTextField!
    @IBOutlet weak var deleteSnapshotLabel2: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAutoBackup(active: SettingsStruct.autoBackupEnable)
        setDeleteSnapshots(active: SettingsStruct.deleteSnapshotEnable)
    }
    
    @IBAction func enableAutoBackup(_ sender: Any) {
        let autoBackupEnabled = SettingsStruct.autoBackupEnable
        SettingsStruct.autoBackupEnable.toggle()
        setAutoBackup(active: !autoBackupEnabled)
    }
    
    @IBAction func autoDeleteSnapshot(_ sender: Any) {
        let deleteSnapshotEnabled = SettingsStruct.deleteSnapshotEnable
        SettingsStruct.deleteSnapshotEnable.toggle()
        setDeleteSnapshots(active: !deleteSnapshotEnabled)
        NotificationCenter
    }
    
    func setAutoBackup(active: Bool) {
        if active {
            autoBackupButton.setActive()
            autoBackupLabel1.textColor = .white
            autoBackupLabel2.textColor = .white
        } else {
            autoBackupButton.setInactive()
            autoBackupLabel1.textColor = .secondaryLabelColor
            autoBackupLabel2.textColor = .secondaryLabelColor
        }
    }
    
    func setDeleteSnapshots(active: Bool) {
        if active {
            deleteSnapshotButton.setActive()
            deleteSnapshotLabel1.textColor = .white
            deleteSnapshotLabel2.textColor = .white
        } else {
            deleteSnapshotButton.setInactive()
            deleteSnapshotLabel1.textColor = .secondaryLabelColor
            deleteSnapshotLabel2.textColor = .secondaryLabelColor
        }
    }
    
}
