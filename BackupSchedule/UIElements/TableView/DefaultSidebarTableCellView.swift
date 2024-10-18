//
// DefaultSidebarTableCellView.swift
// BackupSchedule
//
// Created by Tohr01 on 30.08.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

protocol DefaultSidebarTableCellView: NSTableCellView {
    func setActive()

    func setInactive()
}
