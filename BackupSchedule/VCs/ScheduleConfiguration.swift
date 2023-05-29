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

    @IBOutlet var scheduleListTableView: NSTableView!

    // Right main view
    @IBOutlet var backupDescriptionLabel: NSTextField!
    @IBOutlet var hoursTextField: NSTextField!
    @IBOutlet var minutesTextField: NSTextField!

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
    @IBOutlet var disableWhenInBattery: DefaultButton!
    @IBOutlet var runUnderHighLoad: DefaultButton!

    var schedules: [BackupSchedule] = []
    var newSchedule: Bool = true
    var currentScheduleIdx: Int?

    var tmTargets: [TMDestination] = []
    var selectedDrive: TMDestination?

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshSchedules()
        dayButtons = [monday: "Monday", tuesday: "Tuesday", wednesday: "Wednesday", thursday: "Thursday", friday: "Friday", saturday: "Saturday", sunday: "Sunday"]
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

    @IBAction func save(_: Any) {
        guard let days = getSelectedDaysStr() else {
            defaultAlert(message: "You have to select at least one day for the schedule to run.")
            return
        }
        #warning("todo handle time not set")

        let activeDaysStr = dayButtons.filter(\.key.isActive).map { $0.value.lowercased() }
        let activeDays: [ActiveDays] = activeDaysStr.map { ActiveDays(rawValue: $0) }.compactMap { $0 }

        guard let hours = Int(hoursTextField.stringValue), let minutes = Int(minutesTextField.stringValue) else {
            defaultAlert(message: "You have to set a time for the schedule to run.")
            return
        }
        var activeTime = DateComponents()
        activeTime.hour = hours
        activeTime.minute = minutes
        var newBackupSchedule = BackupSchedule(id: UUID(), displayName: days, activeDays: activeDays, timeActive: activeTime, selectedDrive: selectedDrive, settings: BackupScheduleSettings(startNotification: notifyBackup.isActive, disableWhenBattery: disableWhenInBattery.isActive, runWhenUnderHighLoad: runUnderHighLoad.isActive))
        // If new schedule has been created add to arr and activate
        if newSchedule {
            schedules.append(newBackupSchedule)
            ScheduleCoordinator.default.addToRunLoop(newBackupSchedule)
            saveAllSchedules()
        } else {
            if let currentScheduleIdx = currentScheduleIdx {
                newBackupSchedule.id = schedules[currentScheduleIdx].id
                ScheduleCoordinator.default.removeScheduleFromRunLoop(id: newBackupSchedule.id)
                ScheduleCoordinator.default.addToRunLoop(newBackupSchedule)
                refreshSchedules()
                scheduleListTableView.reloadData()
                saveAllSchedules()
            }
        }
        NotificationCenter.default.post(Notification(name: Notification.Name("scheduleschanged")))
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
            searchDestinations.setActive()
            rotateDests.setInactive()
        } else {
            // if empty no drive has been selected
            selectedDrive = nil
            rotateDests.setActive()
        }
    }

    func refreshSchedules() {
        schedules = Array(ScheduleCoordinator.schedules.keys)
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
        if schedule.settings.startNotification { notifyBackup.setActive() } else { notifyBackup.setInactive() }
        if schedule.settings.disableWhenBattery { disableWhenInBattery.setActive() } else { disableWhenInBattery.setInactive() }
        if schedule.settings.runWhenUnderHighLoad { runUnderHighLoad.setActive() } else { runUnderHighLoad.setInactive() }

        backupDescriptionLabel.stringValue = getDisplayText()
    }

    func loadTemplateSchedule() {
        // Turn all dayButtons off
        _ = dayButtons.keys.map { $0.setInactive() }

        // Set time fields
        hoursTextField.stringValue = "00"
        minutesTextField.stringValue = "00"

        // Set default settings
        notifyBackup.setActive()
        disableWhenInBattery.setInactive()
        runUnderHighLoad.setActive()

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
        lastBackupLabel.stringValue = "Last backup on \(AppDelegate.tm!.getLatestBackup().getLatestBackupString() ?? "")"
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
            timeText = "\(hoursTextField.stringValue) o'clock"
        } else {
            timeText = "\(hoursTextField.stringValue):\(minutesTextField.stringValue)"
        }

        return"\"\(dayText) at \(timeText)\""
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
            defaultAlert(message: "Schedule could not be saved please try restarting the program!")
        }
    }
}

// MARK: -

// MARK: Table View

extension ScheduleConfiguration {
    func configureTableView() {
        scheduleListTableView.selectionHighlightStyle = .none
        scheduleListTableView.allowsMultipleSelection = false
    }

    func numberOfRows(in _: NSTableView) -> Int {
        schedules.count + 1
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

        scheduleCell.runDaysTitle.stringValue = schedules[row].displayName
        scheduleCell.scheduleID = schedules[row].id
        scheduleCell.deleteButton.action = #selector(deleteSchedule(_:))
        scheduleCell.runTime.stringValue = schedules[row].getTimeString()
        return scheduleCell
    }

    func tableViewSelectionDidChange(_: Notification) {
        let selectedRow = scheduleListTableView.selectedRow
        if selectedRow >= 0 {
            // User clicked "Add schedule button"
            if selectedRow == schedules.count {
                loadTemplateSchedule()
                newSchedule = true
                currentScheduleIdx = nil
                return
            } else {
                let schedule = schedules[selectedRow]
                newSchedule = false
                currentScheduleIdx = selectedRow
                loadScheduleUI(schedule)
            }
            scheduleListTableView.deselectRow(selectedRow)
        }
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
            NotificationCenter.default.post(Notification(name: Notification.Name("scheduleschanged")))
        }
    }
}

// MARK: -

// MARK: TextFieldDelegate

extension ScheduleConfiguration: NSTextFieldDelegate {
    func setupTextFields() {
        let hoursFormatter = NumberFormatter()
        hoursFormatter.minimum = 0
        hoursFormatter.maximum = 23

        hoursTextField.formatter = hoursFormatter
    }

    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        if let tf = control as? NSTextField {
            let upperLimit = tf.identifier == NSUserInterfaceItemIdentifier("minutesTF") ? 60 : 23

            if let number = Int(fieldEditor.string), number >= 0, number <= upperLimit {
                NotificationCenter.default.post(Notification(name: Notification.Name("updatedSchedule")))
                return true
            } else {
                let alert = NSAlert()
                alert.messageText = "Invalid Input"
                alert.informativeText = "Please enter a number between 0 and \(upperLimit)."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
                tf.stringValue = "00"
            }
        }
        NotificationCenter.default.post(Notification(name: Notification.Name("updatedSchedule")))
        return false
    }
}

// MARK: -

// MARK: Error handling

extension ScheduleConfiguration {
    func defaultAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.beginSheetModal(for: view.window!)
    }
}
