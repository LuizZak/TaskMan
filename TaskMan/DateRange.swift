//
//  DateRange.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 07/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Foundation
import SwiftyJSON

struct DateRange {
    
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
    
    /// Returns whether this date range intersects with another date range, in inclusive fashion.
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
        
        return DateRange(startDate: start, endDate: end)
    }
    
    /// Returns the union between this and another date range, that is, the minimum date
    /// range capable of containing both date ranges inclusively
    func union(with range: DateRange) -> DateRange {
        return DateRange(startDate: min(startDate, range.startDate), endDate: max(endDate, range.endDate))
    }
}

extension DateRange: Equatable {
    static func ==(lhs: DateRange, rhs: DateRange) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
    }
}
