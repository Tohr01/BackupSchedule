//
// ScheduleConfiguration.swift
// BackupSchedule
//
// Created by Tohr01 on 19.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//


import Cocoa

class ScheduleConfiguration: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var destNameLabel: NSTextField!
    @IBOutlet weak var destCountMoreLabel: NSTextField!
    @IBOutlet weak var lastBackupLabel: NSTextField!
    
    @IBOutlet weak var scheduleListTableView: NSTableView!
    
    // Right main view
    @IBOutlet weak var backupDescriptionLabel: NSTextField!
    @IBOutlet weak var hoursTextField: NSTextField!
    @IBOutlet weak var minutesTextField: NSTextField!
    
    // Day selection buttons
    @IBOutlet weak var monday: DefaultButton!
    @IBOutlet weak var tuesday: DefaultButton!
    @IBOutlet weak var wednesday: DefaultButton!
    @IBOutlet weak var thursday: DefaultButton!
    @IBOutlet weak var friday: DefaultButton!
    @IBOutlet weak var saturday: DefaultButton!
    @IBOutlet weak var sunday: DefaultButton!
    var dayButtons: [DefaultButton : String]!
    
    // Destination selection
    @IBOutlet weak var rotateDests: DefaultButton!
    @IBOutlet weak var searchDestinations: DefaultButton!
    
    // Backup settings
    @IBOutlet weak var notifyBackup: DefaultButton!
    @IBOutlet weak var disableWhenInBattery: DefaultButton!
    @IBOutlet weak var runUnderHighLoad: DefaultButton!
    
    var schedules: [BackupSchedule] = []
    var newSchedule: Bool = true
    
    var tmTargets: [TMDestination] = []
    var selectedDrive: TMDestination?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dayButtons = [monday : "Monday", tuesday : "Tuesday", wednesday : "Wednesday", thursday : "Thursday", friday : "Friday", saturday : "Saturday", sunday : "Sunday"]
        tmTargets = (try? AppDelegate.tm!.getDestinations()) ?? []
        
        configureSidebar()
        configureTableView()
        loadTemplateSchedule()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateScheduleText(_:)), name: Notification.Name("updatedSchedule"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedDestDrive(_:)), name: Notification.Name("selectedDestDrive"), object: nil)
    }
    
    // Deinitilizer
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updatedSchedule"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("selectedDestDrive"), object: nil)
    }

    @IBAction func save(_ sender: Any) {
        // If new schedule has been created add to arr and activate
        if newSchedule {
            guard let days = getSelectedDaysStr() else {
                defaultAlert(message: "You have to select at least one day for the schedule to run.")
                return
            }
#warning("todo handle time not set")
            
            let activeDaysStr = dayButtons.filter({$0.key.isActive}).map({$0.value.lowercased()})
            let activeDays: [ActiveDays] = activeDaysStr.map({ActiveDays(rawValue: $0)}).compactMap({$0})
            
            guard let hours = Int(hoursTextField.stringValue), let minutes = Int(minutesTextField.stringValue) else {
                defaultAlert(message: "You have to set a time for the schedule to run.")
                return
            }
            var activeTime = DateComponents()
            activeTime.hour = hours
            activeTime.minute = minutes
            schedules.append(BackupSchedule(id: UUID(), displayName: days, activeDays: activeDays, timeActive: activeTime, selectedDrive: selectedDrive, settings: BackupScheduleSettings(startNotification: notifyBackup.isActive, disableWhenBattery: disableWhenInBattery.isActive, runWhenUnderHighLoad: runUnderHighLoad.isActive)))
            ScheduleCoordinator.default.addToRunLoop(schedules[0])
            #warning("todo implement safe to user defaults")
        } else {
            
        }
        scheduleListTableView.reloadData()
    }
    
    @IBAction func selectDestinationDrive(_ sender: Any) {
        let popover = NSPopover()
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateController(withIdentifier: "diskSelectVC") as? DiskSelection {
            vc.selectedDrive = selectedDrive
            vc.tmTargets = tmTargets
            popover.contentViewController = vc
            popover.behavior = .transient
            popover.animates = true
            
            popover.show(relativeTo: view.bounds, of: searchDestinations, preferredEdge: .maxX)
        }
    }
    
    @IBAction func rotateDests(_ sender: Any) {
        if !rotateDests.isActive {
            rotateDests.setActive()
            selectedDrive = nil
            searchDestinations.setInactive()
        }
    }
    @objc func updateScheduleText(_ aNotification: Notification) {
        backupDescriptionLabel.stringValue = getDisplayText()
    }
    
    @objc func selectedDestDrive(_ aNotification: Notification) {
        // Get selected drive from notification
        if let selectedDrive = aNotification.object as? TMDestination {
            self.selectedDrive = selectedDrive
            searchDestinations.setActive()
            rotateDests.setInactive()
        } else {
            // if empty no drive has been selected
            selectedDrive = nil
            rotateDests.setActive()
        }
    }
}

// MARK: -
// MARK: Configure view on startup
extension ScheduleConfiguration {
    // SIDEBAR
    
    func configureSidebar() {
        configureDiskNames()
    }
    
    func loadScheduleUI(_ schedule: BackupSchedule) {
        newSchedule = false
        _ = dayButtons.keys.map{$0.setInactive()}
        for activeDay in schedule.activeDays {
            _ = dayButtons.filter({$0.value.lowercased() == activeDay.rawValue.0}).map({$0.key.setActive()})
        }
        
        // Set time fields
        hoursTextField.stringValue = "\(schedule.timeActive.hour ?? 00)"
        minutesTextField.stringValue = "\(schedule.timeActive.minute ?? 00)"
        
        // Set settings
        if schedule.settings.startNotification { notifyBackup.setActive() } else { notifyBackup.setInactive() }
        if schedule.settings.disableWhenBattery { disableWhenInBattery.setActive() } else { disableWhenInBattery.setInactive() }
        if schedule.settings.runWhenUnderHighLoad { runUnderHighLoad.setActive() } else { runUnderHighLoad.setInactive() }
        
        backupDescriptionLabel.stringValue = getDisplayText()
    }
    
    func loadTemplateSchedule() {
        // Turn all dayButtons off
        _ = dayButtons.keys.map{$0.setInactive()}
        
        // Set time fields
        hoursTextField.stringValue = "00"
        minutesTextField.stringValue = "00"
        
        // Set default settings
        notifyBackup.setActive()
        disableWhenInBattery.setInactive()
        runUnderHighLoad.setActive()
        
        backupDescriptionLabel.stringValue = getDisplayText()
    }
    
    func configureDiskNames() {
        destNameLabel.stringValue = (try? AppDelegate.tm?.getPrimaryVolume()?.name) ?? "# Error #"
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
// MARK: Schedule Handle
extension ScheduleConfiguration {
    func getDisplayText() -> String {
        let dayText = getSelectedDaysStr()
        guard let dayText = dayText else {
            return "\"Never\""
        }
        
        var timeText = ""
        
        if let minutes = Int(minutesTextField.stringValue), minutes == 0 {
            timeText = "\(hoursTextField.stringValue) o'clock)"
        } else {
            timeText = "\(hoursTextField.stringValue):\(minutesTextField.stringValue)"
        }
        
        return"\"\(dayText) at \(timeText)\""
    }
    
    func getSelectedDaysStr() -> String? {
        var dayText = ""
        // Reformat days
        // Check for week only active
        if monday.isActive && tuesday.isActive && wednesday.isActive && thursday.isActive && friday.isActive && !sunday.isActive && !saturday.isActive {
            dayText = "Weekdays"
        } else if !monday.isActive && !tuesday.isActive && !wednesday.isActive && !thursday.isActive && !friday.isActive && sunday.isActive && saturday.isActive {
            dayText = "Weekends"
        } else if dayButtons.filter({$0.key.isActive}).count == dayButtons.count {
            dayText = "Every day"
        } else {
            let activeDays = dayButtons.filter({$0.key.isActive}).map({$0.value})
            if activeDays.isEmpty {
                return nil
            }
            dayText = activeDays.joined(separator: ", ")
        }
        return dayText
    }
}


// MARK: -
// MARK: TextFieldDelegate
extension ScheduleConfiguration {
    
    func configureTableView() {
        scheduleListTableView.selectionHighlightStyle = .none
        scheduleListTableView.allowsMultipleSelection = false
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
        scheduleCell.runTime.stringValue = "\(activeTime.hour!):\(activeTime.minute!)"
        return scheduleCell
    }
        
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = scheduleListTableView.selectedRow
        if selectedRow >= 0 {
            // User clicked "Add schedule button"
            if selectedRow == schedules.count {
                loadTemplateSchedule()
                newSchedule = true
                return
            } else {
                let schedule = schedules[selectedRow]
                loadScheduleUI(schedule)
            }
            scheduleListTableView.deselectRow(selectedRow)
        }
    }
}

// MARK: -
// MARK: Error handling
extension ScheduleConfiguration {
    func defaultAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.beginSheetModal(for: self.view.window!)
    }
}
