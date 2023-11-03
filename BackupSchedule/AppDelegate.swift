//
// AppDelegate.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa
import UserNotifications
import ServiceManagement

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    static var tm: TimeMachine?
    
    var window: BackupWindow!
    private var menu: NSMenu!
    private var statusItem: NSStatusItem!
    private var backupTimer: Timer?
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Add helper application to Autolaunch
        let helperBundleId = "codes.cr.BackupScheduleHelper"
        SMLoginItemSetEnabled(helperBundleId as CFString, true)
        ScheduleCoordinator.default.loadSchedules()
        
        
        do {
            AppDelegate.tm = try TimeMachine()
            // Construct menubar appearance
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            if let button = statusItem.button {
                button.image = NSImage(named: "tmicon")
                try constructMenu()
            }
            
            Task {
                await requestNotificationAuth()
            }
            
            #warning("potential remove / performance check todo")
            let autoTaskTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                // Last backup ist too old. Starting new Backup
                if SettingsStruct.autoBackupEnable, let lastBackup = AppDelegate.tm!.getLatestBackup(), lastBackup <= Calendar.current.date(byAdding: .day, value: -SettingsStruct.autoBackupTime, to: Date.now)! {
                    try? AppDelegate.tm!.startBackup()
                    let notification = UNMutableNotificationContent()
                    notification.title = "Started Backup"
                    notification.subtitle = "Your Mac has not been backuped for \(SettingsStruct.autoBackupTime) day(s)"
                    let request = UNNotificationRequest(identifier: "backupNotification", content: notification, trigger: nil)
                    UNUserNotificationCenter.current().add(request)
                }

                if SettingsStruct.deleteSnapshotEnable && SettingsStruct.lastSnapshotDeletionDate <= Calendar.current.date(byAdding: .day, value: -SettingsStruct.deleteSnapshotTime, to: Date.now)! {
                    #warning("todo")
                    let notification = UNMutableNotificationContent()
                    notification.title = "Started Backup"
                    notification.subtitle = "Your Mac has not been backuped for \(SettingsStruct.autoBackupTime) day(s)"
                    let request = UNNotificationRequest(identifier: "backupNotification", content: notification, trigger: nil)
                    UNUserNotificationCenter.current().add(request)
                }
            }
            RunLoop.main.add(autoTaskTimer, forMode: .common)
            
            initUserInterface()
        } catch {
            communicationError()
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(openMainVC(_:)), name: Notification.Name("disabledautobackup"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openMainVC(_:)), name: Notification.Name("tmconfigured"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openMainVC(_:)), name: Notification.Name("informationVC"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenuLabels(_:)), name: Notification.Name.NSCalendarDayChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenuLabels(_:)), name: Notification.Name("scheduleschanged"), object: nil)
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(backupStarted), name: Notification.Name("com.apple.backupd.DestinationMountNotification"), object: nil)
    }
    
}

// MARK: -

// MARK: Window handling

extension AppDelegate {
    @objc func openMainVC(_: Notification?) {
        if AppDelegate.tm!.isAutoBackupEnabled() {
            openVC(title: "Disable AutoBackup", storyboardID: "disableab")
        } else {
            openVC(title: "Schedule Backups", storyboardID: "scheduleconfiguration")
        }
    }
    
    func openVC(title: String, storyboardID: String) {
        if window == nil || !window.isVisible {
            let contentRect = NSRect(x: 0, y: 0, width: 820, height: 498)
            window = BackupWindow(contentRect: contentRect, styleMask: [.closable, .miniaturizable, .titled], backing: .buffered, defer: false)
            
            window.isReleasedWhenClosed = false
            window.center()
            window.title = title
            window.orderFrontRegardless()
            
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            
            if let vc = storyboard.instantiateController(withIdentifier: storyboardID) as? NSViewController {
                window.contentViewController = vc
            }
            
        } else {
            let storyboard: NSStoryboard = .init(name: "Main", bundle: nil)
            
            if let vc = storyboard.instantiateController(withIdentifier: storyboardID) as? NSViewController {
                window.title = title
                window.contentViewController = vc
            }
            window.orderFrontRegardless()
        }
    }
    
    @objc func initUserInterface() {
        do {
            if UserDefaults.standard.value(forKey: "firstLaunch") == nil {
                openVC(title: "Information", storyboardID: "information")
            } else if try !(AppDelegate.tm!.isConfigured()) {
                openVC(title: "Configure TimeMachine", storyboardID: "configuretm")
            } else if AppDelegate.tm!.isAutoBackupEnabled() {
                openVC(title: "Disable AutoBackup", storyboardID: "disableab")
            } else {
                    openMainVC(nil)
                
            }
        } catch {
            communicationError()
            return
        }
    }
}

// MARK: -

// MARK: Notification handling

extension AppDelegate {
    func requestNotificationAuth() async {
        let notificationCenter = UNUserNotificationCenter.current()
        _ = try? await notificationCenter.requestAuthorization(options: [.alert, .sound])
    }
}

// MARK: -

// MARK: Menu construction

extension AppDelegate {
    func constructMenu() throws {
        menu = NSMenu()
        
        do {
            if try !(AppDelegate.tm!.isConfigured()) {
                let notConfiguredItem = NSMenuItem(title: "TimeMachine not configured", action: nil, keyEquivalent: "")
                notConfiguredItem.isEnabled = false
                menu.addItem(notConfiguredItem)
                
            } else {
                let topMenuItem: NSMenuItem = .init(title: "Running Backup...", action: nil, keyEquivalent: "")
                topMenuItem.isEnabled = false
                topMenuItem.identifier = NSUserInterfaceItemIdentifier("topMenuItem")
                
                if let backupRunning = try? AppDelegate.tm!.isBackupRunning(), backupRunning {
                    backupStarted(Notification(name: Notification.Name("com.apple.backupd.DestinationMountNotification")))
                    topMenuItem.title = "Running Backup..."
                    menu.addItem(topMenuItem)
                } else {
                    topMenuItem.title = AppDelegate.tm!.getLatestBackupStr()
                    menu.addItem(topMenuItem)
                }
                
                let nextBackup = NSMenuItem(title: "Next backup:\n\(ScheduleCoordinator.default.getNextExecutionDateStr())", action: nil, keyEquivalent: "")
                nextBackup.identifier = NSUserInterfaceItemIdentifier("nextBackup")
                nextBackup.isEnabled = false
                menu.addItem(nextBackup)
                
                menu.addItem(NSMenuItem.separator())
                
                var backupNowTitle = ""
                if let backupRunning = try? AppDelegate.tm?.isBackupRunning(), backupRunning {
                    backupNowTitle = "Stop Backup"
                    backupStarted(Notification(name: Notification.Name("com.apple.backupd.DestinationMountNotification")))
                } else {
                    backupNowTitle = "Start Backup"
                }
                let backupNowItem = NSMenuItem(title: backupNowTitle, action: #selector(AppDelegate.startBackupWrapper), keyEquivalent: "")
                backupNowItem.identifier = NSUserInterfaceItemIdentifier("backupNow")
                menu.addItem(backupNowItem)
                menu.addItem(NSMenuItem.separator())
            }
        } catch {
            throw error
        }
        let scheduleSettings = NSMenuItem(title: "Schedules...", action: #selector(initUserInterface), keyEquivalent: "")
        menu.addItem(scheduleSettings)
        
        let quitNowitem = NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: "")
        menu.addItem(quitNowitem)
        statusItem.menu = menu
    }
    
    func changeTitleForMenuItem(with identifier: NSUserInterfaceItemIdentifier, to title: String) {
        _ = menu.items.filter { $0.identifier == identifier }.map { $0.title = title }
    }
    
    @objc func updateMenuLabels(_ aNotification: Notification) {
        changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("topMenuItem"), to: AppDelegate.tm!.getLatestBackupStr())
        changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("nextBackup"), to: ScheduleCoordinator.default.getNextExecutionDateStr())
    }
}

// MARK: -

// MARK: TM Listeners

extension AppDelegate {
    @objc func backupStarted(_: Notification) {
        print(try? AppDelegate.tm!.isBackupRunning(), backupTimer)
        // test if backup is running
        if let backupRunning = try? AppDelegate.tm!.isBackupRunning() && backupTimer != nil, !backupRunning { return }
        
        changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("topMenuItem"), to: "Starting backup...")
        changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("backupNow"), to: "Stop backup")
        backupTimer = Timer(timeInterval: 5, target: self, selector: #selector(updateTMProgressMenu), userInfo: nil, repeats: true)
        RunLoop.main.add(backupTimer!, forMode: .common)
    }
    
    @objc func updateTMProgressMenu() {
        print(try? AppDelegate.tm!.isBackupRunning(), try? AppDelegate.tm!.getBackupProgess())
        // Checks if backup finished
        if let backupRunning = try? AppDelegate.tm!.isBackupRunning(), !backupRunning {
            backupTimer?.invalidate()
            backupTimer = nil
            if let lastBackup = AppDelegate.tm!.getLatestKnownBackup() {
                changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("topMenuItem"), to: "\(lastBackup.getLatestBackupString().capitalizeFirst)")
            } else {
                changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("topMenuItem"), to: "No latest Backup found")
            }
            changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("backupNow"), to: "Start Backup")
            NotificationCenter.default.post(Notification(name: Notification.Name("tmchanged")))
            updateMenuLabels(Notification(name: Notification.Name("backupEnded")))
            return
        }
        if let percent = (try? AppDelegate.tm!.getBackupProgess()) {
            changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("topMenuItem"), to: "Backup: \(Int(percent * 100))%")
        } else {
            changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("topMenuItem"), to: "Running backup...")
        }
    }
}

// MARK: -

// MARK: TM Wrapper for menu

extension AppDelegate {
    @objc func startBackupWrapper() {
        if let startBackupMenuItem = menu.items.filter({ $0.identifier == NSUserInterfaceItemIdentifier("backupNow") }).first, startBackupMenuItem.title.lowercased().contains("stop") {
            try? AppDelegate.tm!.stopBackup()
            changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("backupNow"), to: "Start backup")
        } else {
            try? AppDelegate.tm!.startBackup()
        }
    }
    
    @objc func quitApplication() {
        NSApplication.shared.terminate(self)
    }
}

// MARK: -

// MARK: Error handling

extension AppDelegate {
    func communicationError() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Error communicating with TimeMachine. Please report this bug."
        alert.runModal()
    }
}
