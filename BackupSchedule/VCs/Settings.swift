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
    @IBOutlet weak var autoBackupTextFieldContainer: BackgroundView!
    @IBOutlet weak var autoBackupLabel1: ToggleTextField!
    @IBOutlet weak var autoBackupLabel2: ToggleTextField!
    
    @IBOutlet weak var deleteSnapshotButton: DefaultButton!
    @IBOutlet weak var deleteSnapshotTextFieldContainer: BackgroundView!
    @IBOutlet weak var deleteSnapshotLabel1: ToggleTextField!
    @IBOutlet weak var deleteSnapshotLabel2: ToggleTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAutoBackup(active: SettingsStruct.autoBackupEnable)
        setDeleteSnapshots(active: SettingsStruct.deleteSnapshotEnable)
        
        autoBackupLabel1.addClickGestureRecognizer(target: self, selector: #selector(enableAutoBackup(_:)))
        autoBackupLabel2.addClickGestureRecognizer(target: self, selector: #selector(enableAutoBackup(_:)))
        
        deleteSnapshotLabel1.addClickGestureRecognizer(target: self, selector: #selector(autoDeleteSnapshot(_:)))
        deleteSnapshotLabel2.addClickGestureRecognizer(target: self, selector: #selector(autoDeleteSnapshot(_:)))
    }
    
    @IBAction func enableAutoBackup(_ sender: Any) {
        let autoBackupEnabled = SettingsStruct.autoBackupEnable
        SettingsStruct.autoBackupEnable.toggle()
        setAutoBackup(active: !autoBackupEnabled)
        NotificationCenter.default.post(Notification(name: Notification.Name("settingsUpdated")))
    }
    
    @IBAction func autoDeleteSnapshot(_ sender: Any) {
        let deleteSnapshotEnabled = SettingsStruct.deleteSnapshotEnable
        SettingsStruct.deleteSnapshotEnable.toggle()
        setDeleteSnapshots(active: !deleteSnapshotEnabled)
        NotificationCenter.default.post(Notification(name: Notification.Name("settingsUpdated")))
    }
    
    func setAutoBackup(active: Bool) {
        if active {
            autoBackupButton.setActive()
            autoBackupLabel1.textColor = NSColor(named: "defaultTextColorHD")
            autoBackupLabel2.textColor = NSColor(named: "defaultTextColorHD")
        } else {
            autoBackupButton.setInactive()
            autoBackupTextFieldContainer.backgroundColor = .secondaryLabelColor
            autoBackupLabel1.textColor = .secondaryLabelColor
            autoBackupLabel2.textColor = .secondaryLabelColor
        }
    }
    
    func setDeleteSnapshots(active: Bool) {
        if active {
            deleteSnapshotButton.setActive()
            deleteSnapshotTextFieldContainer.backgroundColor = .white
            deleteSnapshotLabel1.textColor = NSColor(named: "defaultTextColorHD")
            deleteSnapshotLabel2.textColor = NSColor(named: "defaultTextColorHD")
        } else {
            deleteSnapshotButton.setInactive()
            deleteSnapshotTextFieldContainer.backgroundColor = .secondaryLabelColor
            deleteSnapshotLabel1.textColor = .secondaryLabelColor
            deleteSnapshotLabel2.textColor = .secondaryLabelColor
        }
    }
    
}
