//
//  DateFormatHelper.swift
//  RESS
//
//  Created by Luiz Fernando Silva on 16/06/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation

/// Default RFC3339 date formatter
let rfc3339DateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    
    return formatter
}()

/// Formats a given date string from the API from RFC3339 format into an Date instance
func dateTimeFromRFC3339(string: String) -> Date? {
    return rfc3339DateTimeFormatter.date(from: string)
}

/// Formats a given date into a RFC3339 date stirng
func rfc3339StringFrom(date: Date) -> String {
    return rfc3339DateTimeFormatter.string(from: date)
}

func formatTimestamp(_ timestamp: TimeInterval, withMode mode: TimestampMode = .hoursMinutesSeconds) -> String {
    let hours = timestamp / 60 / 60
    let minutes = (timestamp / 60).truncatingRemainder(dividingBy: 60)
    
    switch mode {
    case .hoursMinutesSeconds:
        let seconds = timestamp.truncatingRemainder(dividingBy: 60)
        
        return String(format: "%02d:%02d:%02d", Int(hours), Int(minutes), Int(seconds))
        
    case .hoursMinutes:
        return String(format: "%02d:%02d", Int(hours), Int(minutes))
    }
}

/// Formats a timestamp with hours, minutes and components only if these components are present.
/// Eg:
/// 3600 -> '01h'
/// 3601 -> '01h01s'
/// 4600 -> '01h16m40s'
func formatTimestampCompact(_ timestamp: TimeInterval) -> String {
    let minutes = Int((timestamp / 60).truncatingRemainder(dividingBy: 60))
    let seconds = Int(timestamp.truncatingRemainder(dividingBy: 60))
    let hours = Int(timestamp / 60 / 60)
    
    var output = ""
    
    if hours > 0 {
        output += String(format: "%02dh", hours)
    }
    if minutes > 0 {
        output += String(format: "%02dm", minutes)
    }
    if seconds > 0 {
        output += String(format: "%02ds", seconds)
    }
    
    // Empty time - return 0s string
    if output == "" {
        output = "0s"
    }
    
    return output
}

/// Specifies the mode for a timestamp generation with the formatTimestamp function
enum TimestampMode {
    case hoursMinutesSeconds
    case hoursMinutes
}
