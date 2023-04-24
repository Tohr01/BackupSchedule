//
// String.swift
// BackupSchedule
//
// Created by Tohr01 on 24.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Foundation

extension String {
    var capitalizeFirst: String {
        let firstLetter = self.prefix(1).capitalized
        return firstLetter + self.dropFirst()
    }
}
