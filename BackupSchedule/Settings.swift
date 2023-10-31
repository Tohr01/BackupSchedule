//
// Settings.swift
// BackupSchedule
//
// Created by Tohr01 on 30.10.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Foundation

struct SettingsStruct {
    static var autoBackupEnable: Bool {
        get {
            return (UserDefaults.standard.value(forKey: "autoBackupEnable") as? Bool) ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoBackupEnable")
        }
    }
    static var autoBackupTime: Int {
        get {
            return (UserDefaults.standard.value(forKey: "autoBackupTime") as? Int) ?? 1
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoBackupTime")
        }
    }
    
    static var deleteSnapshotEnable: Bool {
        get {
            return (UserDefaults.standard.value(forKey: "deleteSnapshotsEnable") as? Bool) ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "deleteSnapshotsEnable")
        }
    }
    static var deleteSnapshotTime: Int {
        get {
            return (UserDefaults.standard.value(forKey: "deleteSnapshotsTime") as? Int) ?? 1
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "deleteSnapshotsTime")
        }
    }
}
