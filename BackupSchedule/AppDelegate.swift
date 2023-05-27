//
// AppDelegate.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    static var tm: TimeMachine?
    var window: NSWindow!
    private var menu: NSMenu!
    private var statusItem: NSStatusItem!
    private var backupTimer: Timer?
    func applicationDidFinishLaunching(_: Notification) {
        ScheduleCoordinator.default.loadSchedules()
        ScheduleCoordinator.default.getNextExecutionDate()
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

            initUserInterface()
        } catch {
            communicationError()
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(openMainVC(_:)), name: Notification.Name("disabledautobackup"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openMainVC(_:)), name: Notification.Name("tmconfigured"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(schedulesChanged(_:)), name: Notification.Name("scheduleschanged"), object: nil)

        DistributedNotificationCenter.default().addObserver(self, selector: #selector(backupStarted(_:)), name: Notification.Name("com.apple.backupd.DestinationMountNotification"), object: nil)
    }

    func applicationWillTerminate(_: Notification) {
        let workspaceNC = NSWorkspace.shared.notificationCenter
        workspaceNC.removeObserver(self, name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        workspaceNC.removeObserver(self, name: NSWorkspace.didTerminateApplicationNotification, object: nil)
    }

    func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
        true
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
            window = NSWindow(contentRect: contentRect, styleMask: [.closable, .miniaturizable, .titled], backing: .buffered, defer: false)

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
            if try !(AppDelegate.tm!.isConfigured()) {
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
    #warning("todo menu creation")
    func constructMenu() throws {
        menu = NSMenu()

        do {
            if try !(AppDelegate.tm!.isConfigured()) {
                let notConfiguredItem = NSMenuItem(title: "TimeMachine not configured", action: nil, keyEquivalent: "")
                notConfiguredItem.isEnabled = false
                menu.addItem(notConfiguredItem)

            } else {
                let topMenuItem: NSMenuItem = .init(title: "Running backup...", action: nil, keyEquivalent: "")
                topMenuItem.isEnabled = false
                topMenuItem.identifier = NSUserInterfaceItemIdentifier("topMenuItem")

                if let backupRunning = try? AppDelegate.tm!.isBackupRunning(), backupRunning {
                    backupStarted(Notification(name: Notification.Name("com.apple.backupd.DestinationMountNotification")))
                    topMenuItem.title = "Running backup..."
                    menu.addItem(topMenuItem)
                } else if let lastBackupDate = AppDelegate.tm!.getLatestBackup() {
                    topMenuItem.title = "Last backup: \(lastBackupDate.getLatestBackupString().capitalizeFirst)"
                    menu.addItem(topMenuItem)
                }

                var nextBackup = NSMenuItem(title: "Next backup:\n\(ScheduleCoordinator.default.getNextExecutionDate()?.getLatestBackupString().capitalizeFirst ?? " No backup planned")", action: nil, keyEquivalent: "")
                nextBackup.identifier = NSUserInterfaceItemIdentifier("nextBackup")
                nextBackup.isEnabled = false
                menu.addItem(nextBackup)

                menu.addItem(NSMenuItem.separator())

                let backupNowItem = NSMenuItem(title: "Start Backup", action: #selector(AppDelegate.startBackupWrapper), keyEquivalent: "")
                backupNowItem.identifier = NSUserInterfaceItemIdentifier("backupNow")
                menu.addItem(backupNowItem)
                menu.addItem(NSMenuItem.separator())
            }
        } catch {
            throw error
        }
        let preferences = NSMenuItem(title: "Preferences...", action: #selector(initUserInterface), keyEquivalent: "")
        menu.addItem(preferences)

        let quitNowitem = NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: "")
        menu.addItem(quitNowitem)
        statusItem.menu = menu
    }

    func changeTitleForMenuItem(with identifier: NSUserInterfaceItemIdentifier, to title: String) {
        _ = menu.items.filter { $0.identifier == identifier }.map { $0.title = title }
    }
}

// MARK: -

// MARK: TM Listeners

extension AppDelegate {
    @objc func backupStarted(_: Notification) {
        // test if backup is running
        if let backupRunning = try? AppDelegate.tm!.isBackupRunning(), !backupRunning { return }

        changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("topMenuItem"), to: "Starting backup...")
        changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("backupNow"), to: "Stop backup")
        backupTimer = Timer(timeInterval: 5, target: self, selector: #selector(updateTMProgressMenu), userInfo: nil, repeats: true)
        RunLoop.main.add(backupTimer!, forMode: .common)
    }

    @objc func updateTMProgressMenu() {
        // Checks if backup finished
        if let backupRunning = try? AppDelegate.tm!.isBackupRunning(), !backupRunning {
            backupTimer?.invalidate()
            backupTimer = nil
            changeTitleForMenuItem(with: NSUserInterfaceItemIdentifier("topMenuItem"), to: "\(AppDelegate.tm!.getLatestBackup().getLatestBackupString()?.capitalizeFirst ?? "No latest Backup found")")
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

// MARK: Schedule handling

extension AppDelegate {
    @objc func schedulesChanged(_: Notification) {
        if let nextBackupMenuItem = menu.items.filter({ $0.identifier == NSUserInterfaceItemIdentifier("nextBackup") }).first {
            nextBackupMenuItem.title = "Next backup:\n\(ScheduleCoordinator.default.getNextExecutionDate()?.getLatestBackupString().capitalizeFirst ?? " No backup planned")"
        }
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
