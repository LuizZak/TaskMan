//
//  TaskSegment.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 16/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

/// Represents a segment in time in which a task was executed
struct TaskSegment {
    
    /// The identifier type for task segments
    typealias IDType = Int
    
    /// Unique ID of this task segment
    var id: IDType
    
    /// ID of the associated task
    var taskId: Task.IDType
    
    /// The start/end date ranges for this task
    var range: DateRange
}

extension TaskSegment: Equatable {
    static func ==(lhs: TaskSegment, rhs: TaskSegment) -> Bool {
        return lhs.id == rhs.id && lhs.taskId == rhs.taskId && lhs.range == rhs.range
    }
}

struct DateRange {
    /// Start date of range
    var startDate: Date
    
    /// End date of range
    var endDate: Date
    
    /// Time interval between start and end dates
    var timeInterval: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
}

extension DateRange: Equatable {
    static func ==(lhs: DateRange, rhs: DateRange) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
    }
}
