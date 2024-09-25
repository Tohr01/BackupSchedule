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
    @IBOutlet weak var autoBackupTextField: NumericalTextField!
    @IBOutlet weak var autoBackupLabel1: ToggleTextField!
    @IBOutlet weak var autoBackupLabel2: ToggleTextField!
    var autoBackupProxy: SelectionUIProxy!
    
    @IBOutlet weak var deleteSnapshotButton: DefaultButton!
    @IBOutlet weak var deleteSnapshotTextFieldContainer: BackgroundView!
    @IBOutlet weak var deleteSnapshotTextField: NumericalTextField!
    @IBOutlet weak var deleteSnapshotLabel1: ToggleTextField!
    @IBOutlet weak var deleteSnapshotLabel2: ToggleTextField!
    var autoDeleteSnapshot: SelectionUIProxy!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autoBackupTextField.stringValue = String(SettingsStruct.autoBackupTime)
        deleteSnapshotTextField.stringValue = String(SettingsStruct.deleteSnapshotTime)

        // Toggle AutoBackup
        let toggleAutoBackup = {
            SettingsStruct.autoBackupEnable.toggle()
            NotificationCenter.default.post(Notification(name: Notification.Name("settingsUpdated")))
        }
        autoBackupProxy = SelectionUIProxy(onClick: toggleAutoBackup, checkbox: autoBackupButton, toggleLabels: [autoBackupLabel1, autoBackupLabel2], textField: autoBackupTextField, active: SettingsStruct.autoBackupEnable)
        
        // Toggle DeleteSnapshot
        let toggleDeleteSnapshot = {
            SettingsStruct.deleteSnapshotEnable.toggle()
            NotificationCenter.default.post(Notification(name: Notification.Name("settingsUpdated")))
        }
        autoDeleteSnapshot = SelectionUIProxy(onClick: toggleDeleteSnapshot, checkbox: deleteSnapshotButton, toggleLabels: [deleteSnapshotLabel1, deleteSnapshotLabel2], textField: deleteSnapshotTextField, active: SettingsStruct.deleteSnapshotEnable)
    }
    
    @IBAction func back(_ sender: Any) {
        if !autoBackupTextField.isValid() {
            autoBackupTextField.displayAlert()
            autoBackupTextField.resetToDefault()
            return
        }
        if !deleteSnapshotTextField.isValid() {
            deleteSnapshotTextField.displayAlert()
            deleteSnapshotTextField.resetToDefault()
            return
        }
        SettingsStruct.autoBackupTime = autoBackupTextField.getInt()!
        SettingsStruct.deleteSnapshotTime = deleteSnapshotTextField.getInt()!
        NotificationCenter.default.post(Notification(name: Notification.Name("closeSettings")))
    }

}
