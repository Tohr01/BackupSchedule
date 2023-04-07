//
// ScheduleConfiguration.swift
// BackupSchedule
//
// Created by Tohr01 on 19.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//


import Cocoa

class ScheduleConfiguration: NSViewController, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var destNameLabel: NSTextField!
    @IBOutlet weak var destCountMoreLabel: NSTextField!
    @IBOutlet weak var lastBackupLabel: NSTextField!
    
    @IBOutlet var scheduleListTableView: NSTableView!
    
    // Right main view
    @IBOutlet weak var backupDescriptionLabel: NSTextField!
    @IBOutlet weak var hoursTextField: NSTextField!
    @IBOutlet weak var minutesTextField: NSTextField!
    
    var schedules: [BackupSchedule] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        configureSidebar()
        configureTextFields()
        configureTableView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSchedule(_:)), name: Notification.Name("updatedschedule"), object: nil)
    }
    
    // Deinitilizer
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updatedschedule"), object: nil)
    }

    @objc func updateSchedule(_ aNotification: Notification) {
        backupDescriptionLabel.stringValue = ""
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
    
    // CONFIGURE TEXT FIELDS
    
    func configureTextFields() {
        hoursTextField.delegate = self
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.minimum = 0
        formatter.maximum = 23
        
        hoursTextField.formatter = formatter
    }
}

// MARK: -
// MARK: TextFieldDelegate
extension ScheduleConfiguration {
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            let isValid = self.control(textField, isValidObject: textField.objectValue)
            print(isValid)
        }
    }
        func control(_ control: NSControl, isValidObject obj: Any?) -> Bool {
            // Ensure the input value is valid
            guard let number = obj as? Int else {
                return false
            }
            return (number >= 0 && number < 23)
        }
}

// MARK: -
// MARK: TextFieldDelegate
extension ScheduleConfiguration {
    
    func configureTableView() {
        scheduleListTableView.selectionHighlightStyle = .none
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return schedules.count+1
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row == schedules.count {
            guard let addCell = scheduleListTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("addSchedule"), owner: self) as? AddScheduleCellView else {
                return nil
            }
            return addCell
        }
        
        guard let scheduleCell = scheduleListTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("scheduleCell"), owner: self) as? SidebarTableCellView else {
            return nil
        }
        
        scheduleCell.runDaysTitle.stringValue = schedules[row].displayName
        let activeTime = schedules[row].timeActive
        scheduleCell.runTime.stringValue = "\(activeTime.hour):\(activeTime.minute)"
        return scheduleCell
    }
        
    
}
