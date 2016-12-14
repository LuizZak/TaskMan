//
//  TaskManState.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

/// Basic structure that bundles a TaskMan state
struct TaskManState {
    
    /// The task list associated with this state, containing the tasks and
    /// segments stored
    var taskList: TaskList
    
    /// A currently running segment, if any.
    var runningSegmentId: TaskSegment.IDType?
    
    /// The date range for displaying the default timeline with
    var timeRange: DateRange
    
    /// The creation date for this state
    var creationDate: Date
    
    /// Inits a TaskMan state with the given set of data
    init(taskList: TaskList, runningSegmentId: TaskSegment.IDType, timeRange: DateRange, creationDate: Date = Date()) {
        self.taskList = taskList
        self.runningSegmentId = runningSegmentId
        self.timeRange = timeRange
        self.creationDate = creationDate
    }
    
    /// Inits a TaskMan state with an empty set of data, and a creation date set to this moment
    init(range: DateRange) {
        taskList = TaskList()
        timeRange = range
        creationDate = Date()
    }
}
