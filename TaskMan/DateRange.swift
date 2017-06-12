//
//  DateRange.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 07/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Foundation

/// Represents a period of time with a fixed start and end.
struct DateRange: Codable {
    
    /// Start date of range
    var startDate: Date
    
    /// End date of range
    var endDate: Date
    
    /// Time interval between start and end dates
    var timeInterval: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    /// Returns whether the given date is located within this date range's start
    /// and end dates
    func contains(date: Date) -> Bool {
        return self.startDate <= date && self.endDate >= date
    }
    
    /// Returns whether the given date range is located completely within this date
    /// range's start and end dates
    func contains(range: DateRange) -> Bool {
        return self.startDate <= range.startDate && self.endDate >= range.endDate
    }
    
    /// Returns whether this date range intersects with another date range, in
    /// inclusive fashion.
    /// That means ranges with start/end regions that have the same dates return
    /// `true`.
    func intersects(with range: DateRange) -> Bool {
        return self.startDate <= range.endDate && range.startDate <= self.endDate
    }
    
    /// Returns the intersection date range between this date and another date range.
    /// Returns nil, if the ranges do not intersect one another
    func intersection(with range: DateRange) -> DateRange? {
        if (endDate <= range.startDate || range.endDate <= startDate) {
            return nil
        }
        
        let start = max(startDate, range.startDate)
        let end = min(endDate, range.endDate)
        
        return start...end
    }
    
    /// Returns the union between this and another date range, that is, the minimum
    /// date range capable of containing both date ranges inclusively
    func union(with range: DateRange) -> DateRange {
        return min(startDate, range.startDate)...max(endDate, range.endDate)
    }
    
    /// Splits this date range into two equally sized ranges that join at the middle.
    /// Final ranges have the same total combined time range as this date range.
    func splitAtMiddle() -> (left: DateRange, right: DateRange) {
        let mid = startDate + endDate.timeIntervalSince(startDate) / 2
        
        let left = startDate...mid
        let right = mid...endDate
        
        return (left, right)
    }
}

extension DateRange: Equatable {
    static func ==(lhs: DateRange, rhs: DateRange) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
    }
}

extension Date {
    /// Creates a date range that starts and ends at two specified values.
    ///
    /// - Parameters:
    ///   - lhs: Starting date of range. Must be earlier-or-exactly-equal-to rhs
    ///   - rhs: Ending date of the range.
    /// - Precondition: `lhs <= rhs`
    /// - Returns: A date range with the specified dates.
    static func ...(lhs: Date, rhs: Date) -> DateRange {
        precondition(lhs <= rhs)
        return DateRange(startDate: lhs, endDate: rhs)
    }
}
