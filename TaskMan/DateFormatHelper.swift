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
