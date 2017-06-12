//
//  TaskSegment.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 16/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

/// Represents a segment in time in which a task was executed
struct TaskSegment: Codable {
    
    /// The identifier type for task segments
    typealias IDType = Int
    
    /// Unique ID of this task segment
    var id: IDType
    
    /// ID of the associated task
    var taskId: Task.IDType
    
    /// The start/end date ranges for this task
    var range: DateRange
    
    init(id: Int, taskId: Task.IDType, range: DateRange) {
        self.id = id
        self.taskId = taskId
        self.range = range
    }
}

extension TaskSegment: Equatable {
    static func ==(lhs: TaskSegment, rhs: TaskSegment) -> Bool {
        return lhs.id == rhs.id && lhs.taskId == rhs.taskId && lhs.range == rhs.range
    }
}
