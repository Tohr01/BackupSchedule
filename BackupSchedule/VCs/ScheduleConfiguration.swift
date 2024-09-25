//
// ScheduleConfiguration.swift
// BackupSchedule
//
// Created by Tohr01 on 19.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

class ScheduleConfiguration: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet var destNameLabel: NSTextField!
    @IBOutlet var destCountMoreLabel: NSTextField!
    @IBOutlet var lastBackupLabel: NSTextField!
    
    @IBOutlet var sidebarBackgroundView: BackgroundView!
    @IBOutlet var scheduleListTableView: NSTableView!
    
    // Right main view
    @IBOutlet var backupDescriptionLabel: NSTextField!
    @IBOutlet var hoursTextField: NumericalTextField!
    @IBOutlet var minutesTextField: NumericalTextField!
    
    // Day selection buttons
    @IBOutlet var monday: DefaultButton!
    @IBOutlet var tuesday: DefaultButton!
    @IBOutlet var wednesday: DefaultButton!
    @IBOutlet var thursday: DefaultButton!
    @IBOutlet var friday: DefaultButton!
    @IBOutlet var saturday: DefaultButton!
    @IBOutlet var sunday: DefaultButton!
    var dayButtons: [DefaultButton: String]!
    
    // Destination selection
    @IBOutlet var rotateDests: DefaultButton!
    @IBOutlet var searchDestinations: DefaultButton!
    
    // Backup settings
    @IBOutlet var notifyBackup: DefaultButton!
    @IBOutlet var notifyBackupLabel: ToggleTextField!
    var notifyBackupProxy: SelectionUIProxy!
    @IBOutlet var disableWhenInBattery: DefaultButton!
    @IBOutlet var disableWhenInBatteryLabel: ToggleTextField!
    var disableWhenInBatteryProxy: SelectionUIProxy!
    @IBOutlet var runUnderHighLoad: DefaultButton!
    @IBOutlet var runUnderHighLoadLabel: ToggleTextField!
    var runUnderHighLoadProxy: SelectionUIProxy!
    
    // Global settings
    @IBOutlet var settingsButton: NSButton!
    @IBOutlet var settingsBackgroundContainer: BackgroundView!
    @IBOutlet var settingsContainer: NSView!
    
    var schedules: [BackupSchedule] = []
    var newSchedule: Bool = true
    var currentScheduleIdx: Int?
    
    var tmTargets: [TMDestination] = []
    var selectedDrive: TMDestination?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("VIEW LOADING: \(Date.timeIntervalSinceReferenceDate)")
        refreshSchedules()
        dayButtons = [monday: "Monday", tuesday: "Tuesday", wednesday: "Wednesday", thursday: "Thursday", friday: "Friday", saturday: "Saturday", sunday: "Sunday"]
        tmTargets = (try? AppDelegate.tm!.getDestinations()) ?? []
        
        configureSidebar()
        configureLastBackup()
        configureTableView()
        configureSettings()
        configureSelectionProxies()
        loadTemplateSchedule()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateScheduleText(_:)), name: Notification.Name("updatedSchedule"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedDestDrive(_:)), name: Notification.Name("selectedDestDrive"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tmeventHandler(_:)), name: Notification.Name("tmchanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeSettings(_:)), name: Notification.Name("closeSettings"), object: nil)
    }
    // Deinitilizer
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updatedSchedule"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("selectedDestDrive"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("tmchanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("closeSettings"), object: nil)
    }
    
    override func viewDidAppear() {
        print("VIEW APPEAR: \(Date.timeIntervalSinceReferenceDate)")
    }
    
    @IBAction func save(_: Any) {
        guard let days = getSelectedDaysStr() else {
            view.window!.defaultAlert(message: "You have to select at least one day for the schedule to run.")
            return
        }
        
        let activeDaysStr = dayButtons.filter(\.key.isActive).map { $0.value.lowercased() }
        let activeDays: [ActiveDays] = activeDaysStr.map { ActiveDays(rawValue: $0) }.compactMap { $0 }
        
        if !hoursTextField.isValid() {
            hoursTextField.displayAlert()
            return
        }
        if !minutesTextField.isValid() {
            minutesTextField.displayAlert()
            return
        }
        var activeTime = DateComponents()
        activeTime.hour = Int(hoursTextField.stringValue)!
        activeTime.minute = Int(minutesTextField.stringValue)!
        
        var newBackupSchedule = BackupSchedule(id: UUID(), displayName: days, activeDays: activeDays, timeActive: activeTime, selectedDrive: selectedDrive, settings: BackupScheduleSettings(startNotification: notifyBackupProxy.active, disableWhenBattery: disableWhenInBatteryProxy.active, runWhenUnderHighLoad: runUnderHighLoadProxy.active))
        // If new schedule has been created add to arr and activate
        if newSchedule {
            schedules.append(newBackupSchedule)
            ScheduleCoordinator.default.addSchedule(newBackupSchedule)
            saveAllSchedules()
            loadTemplateSchedule()
        } else {
            if let currentScheduleIdx = currentScheduleIdx {
                newBackupSchedule.id = schedules[currentScheduleIdx].id
                ScheduleCoordinator.default.replaceSchedule(newBackupSchedule)
                refreshSchedules()
                scheduleListTableView.reloadData()
                saveAllSchedules()
            }
        }
        NotificationCenter.default.post(Notification(name: Notification.Name("schedulesChanged")))
        scheduleListTableView.reloadData()
    }
    
    @IBAction func selectDestinationDrive(_: Any) {
        let popover = NSPopover()
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateController(withIdentifier: "diskSelectVC") as? DiskSelection {
        vc.selectedDrive = selectedDrive
            vc.tmTargets = tmTargets
            popover.contentViewController = vc
            popover.behavior = .transient
            popover.animates = true
            searchDestinations.setActive()
            rotateDests.setInactive()
            popover.show(relativeTo: view.bounds, of: searchDestinations, preferredEdge: .maxX)
        }
    }
    
    @IBAction func rotateDests(_: Any) {
        if !rotateDests.isActive {
            rotateDests.setActive()
            selectedDrive = nil
            searchDestinations.setInactive()
        }
    }
    
    @objc func updateScheduleText(_: Notification) {
        backupDescriptionLabel.stringValue = getDisplayText()
    }
    
    @objc func selectedDestDrive(_ aNotification: Notification) {
        // Get selected drive from notification
        if let selectedDrive = aNotification.object as? TMDestination {
            self.selectedDrive = selectedDrive
        } else {
            // if empty no drive has been selected
            selectedDrive = nil
            searchDestinations.setInactive()
            rotateDests.setActive()
        }
    }
    
    func refreshSchedules() {
        schedules = Array(ScheduleCoordinator.schedules.map{$0.0})
    }
    
    @objc func tmeventHandler(_ aNotification: Notification) {
        configureLastBackup()
    }
    
    @IBAction func openSettings(_ sender: Any) {
        showSettings()
    }
    
    @objc func closeSettings(_ aNotification: Notification) {
        hideSettings()
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
        _ = dayButtons.keys.map { $0.setInactive() }
        for activeDay in schedule.activeDays {
            _ = dayButtons.filter { $0.value.lowercased() == activeDay.rawValue.0 }.map { $0.key.setActive() }
        }
        
        // Set time fields
        hoursTextField.stringValue = "\(schedule.getHourString())"
        minutesTextField.stringValue = "\(schedule.getMinuteString())"
        
        // Set settings
        if schedule.settings.startNotification { notifyBackupProxy.setActive() } else { notifyBackupProxy.setInactive() }
        if schedule.settings.disableWhenBattery { disableWhenInBatteryProxy.setActive() } else { disableWhenInBatteryProxy.setInactive() }
        if schedule.settings.runWhenUnderHighLoad { runUnderHighLoadProxy.setActive() } else { runUnderHighLoadProxy.setInactive() }
        if let destinationDrive = schedule.selectedDrive {
            rotateDests.setInactive()
            searchDestinations.setActive()
            selectedDrive = destinationDrive
        }
        backupDescriptionLabel.stringValue = getDisplayText()
    }
    
    func loadTemplateSchedule() {
        // Turn all dayButtons off
        _ = dayButtons.keys.map { $0.setInactive() }
        
        // Set time fields
        hoursTextField.stringValue = "00"
        minutesTextField.stringValue = "00"
        
        // Set default settings
        notifyBackupProxy.setActive()
        disableWhenInBatteryProxy.setInactive()
        runUnderHighLoadProxy.setActive()
        
        backupDescriptionLabel.stringValue = getDisplayText()
        
        rotateDests.setActive()
        selectedDrive = nil
        searchDestinations.setInactive()
    }
    
    func configureDiskNames() {
        destNameLabel.stringValue = (try? AppDelegate.tm?.getPrimaryVolume()?.name) ?? "# Error #"
        var volumeCount = (try? AppDelegate.tm?.getBackupVolumeCount()) ?? 1
        volumeCount -= 1
        
        if volumeCount == 0 {
            destCountMoreLabel.isHidden = true
        } else {
            destCountMoreLabel.stringValue = "\(volumeCount) more"
        }
    }
    
    func configureLastBackup() {
        if let lastBackup = AppDelegate.tm!.getLatestKnownBackup() {
            lastBackupLabel.stringValue = "Last Backup \(lastBackup.getLatestBackupString())"
        } else {
            lastBackupLabel.stringValue = "No last Backup found"
        }
    }
    
    func configureSettings() {
        settingsBackgroundContainer.isHidden = true
        settingsBackgroundContainer.alphaValue = 0
        
        settingsContainer.wantsLayer = true
        settingsContainer.layer?.masksToBounds = true
        settingsContainer.layer?.cornerRadius = 7
    }
    
    func configureSelectionProxies() {
        notifyBackupProxy = SelectionUIProxy(onClick: {}, checkbox: notifyBackup, toggleLabels: [notifyBackupLabel])
        disableWhenInBatteryProxy = SelectionUIProxy(onClick: {}, checkbox: disableWhenInBattery, toggleLabels: [disableWhenInBatteryLabel])
        runUnderHighLoadProxy = SelectionUIProxy(onClick: {}, checkbox: runUnderHighLoad, toggleLabels: [runUnderHighLoadLabel])
    }
}

// MARK: -

// MARK: Schedule Handle

extension ScheduleConfiguration {
    func getDisplayText() -> String {
        let dayText = getSelectedDaysStr()
        guard let dayText = dayText else {
            return "Never"
        }
        
        var timeText = ""
        
        if let minutes = Int(minutesTextField.stringValue), minutes == 0 {
            timeText = "\(Int(hoursTextField.stringValue) ?? 0) o'clock"
        } else {
            timeText = "\(hoursTextField.stringValue):\(minutesTextField.stringValue)"
        }
        
        return "\(dayText) at \(timeText)"
    }
    
    func getSelectedDaysStr() -> String? {
        var dayText = ""
        // Reformat days
        // Check for week only active
        if monday.isActive, tuesday.isActive, wednesday.isActive, thursday.isActive, friday.isActive, !sunday.isActive, !saturday.isActive {
            dayText = "Weekdays"
        } else if !monday.isActive, !tuesday.isActive, !wednesday.isActive, !thursday.isActive, !friday.isActive, sunday.isActive, saturday.isActive {
            dayText = "Weekends"
        } else if dayButtons.filter(\.key.isActive).count == dayButtons.count {
            dayText = "Every day"
        } else {
            let activeDays = dayButtons.filter(\.key.isActive).map(\.value)
            if activeDays.isEmpty {
                return nil
            }
            dayText = activeDays.joined(separator: ", ")
        }
        return dayText
    }
    
    func saveAllSchedules() {
        do {
            var schedulesEnc: [Data] = []
            for schedule in schedules {
                let data = try JSONEncoder().encode(schedule)
                schedulesEnc.append(data)
            }
            UserDefaults.standard.set(schedulesEnc, forKey: "schedules")
        } catch {
            view.window!.defaultAlert(message: "Schedule could not be saved please try restarting the program!")
        }
    }
}

// MARK: -

// MARK: Table View

extension ScheduleConfiguration {
    func configureTableView() {
        scheduleListTableView.selectionHighlightStyle = .none
        scheduleListTableView.allowsMultipleSelection = false
        scheduleListTableView.action = #selector(rowClicked)
    } 
    
    func numberOfRows(in _: NSTableView) -> Int {
        return schedules.count + 1
    }
    
    func tableView(_: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        if row == schedules.count {
            guard let addCell = scheduleListTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("addSchedule"), owner: self) as? AddScheduleCellView else {
                return nil
            }
            return addCell
        }
        guard let scheduleCell = scheduleListTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("scheduleCell"), owner: self) as? SidebarTableCellView else {
            return nil
        }
        scheduleCell.setInactive()
        scheduleCell.runDaysTitle.stringValue = schedules[row].displayName
        scheduleCell.scheduleID = schedules[row].id
        scheduleCell.deleteButton.action = #selector(deleteSchedule(_:))
        scheduleCell.runTime.stringValue = schedules[row].getTimeString()
        return scheduleCell
    }
    
    @objc func rowClicked() {
        let clickedRow = scheduleListTableView.clickedRow
        let clickedCell = scheduleListTableView.view(atColumn: 0, row: clickedRow, makeIfNecessary: false) as? DefaultSidebarTableCellView
        if clickedRow >= 0 {
            // User clicked "Add schedule button"
            if clickedRow == schedules.count {
                loadTemplateSchedule()
                newSchedule = true
                currentScheduleIdx = nil
            } else {
                let schedule = schedules[clickedRow]
                newSchedule = false
                currentScheduleIdx = clickedRow
                loadScheduleUI(schedule)
            }
        }
        for cellIdx in 0..<scheduleListTableView.numberOfRows {
            let cell = scheduleListTableView.view(atColumn: 0, row: cellIdx, makeIfNecessary: false) as? DefaultSidebarTableCellView
            cell?.setInactive()
        }
        clickedCell?.setActive()
    }
    
    @objc func deleteSchedule(_ sender: Any) {
        if let defaultButton = sender as? DefaultButton, let cell = defaultButton.superview?.superview as? SidebarTableCellView, let id = cell.scheduleID {
            var currentScheduleID: UUID?
            if let currentScheduleIdx = currentScheduleIdx {
                if id == schedules[currentScheduleIdx].id {
                    loadTemplateSchedule()
                    newSchedule = true
                    self.currentScheduleIdx = nil
                } else {
                    currentScheduleID = schedules[currentScheduleIdx].id != id ? schedules[currentScheduleIdx].id : nil
                }
            }
            ScheduleCoordinator.default.removeScheduleFromRunLoop(id: id)
            refreshSchedules()
            if let currentScheduleID = currentScheduleID {
                currentScheduleIdx = schedules.firstIndex(where: { $0.id == currentScheduleID })
            }
            scheduleListTableView.reloadData()
            saveAllSchedules()
            NotificationCenter.default.post(Notification(name: Notification.Name("schedulesChanged")))
        }
    }
}

// MARK: -
// MARK: Settings
extension ScheduleConfiguration {
    func showSettings() {
        settingsBackgroundContainer.isHidden = false
        NSAnimationContext.runAnimationGroup { context in
            context.allowsImplicitAnimation = true
            context.duration = 0.5
            settingsBackgroundContainer.animator().alphaValue = 1
        }
    }
    
    func hideSettings() {
        NSAnimationContext.runAnimationGroup { context in
            context.allowsImplicitAnimation = true
            context.duration = 0.3
            settingsBackgroundContainer.animator().alphaValue = 0
        } completionHandler: {
            self.settingsBackgroundContainer.isHidden = true
        }
    }
}
