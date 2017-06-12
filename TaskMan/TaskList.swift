//
//  TaskList.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

/// Describes a collection of tasks.
/// Used mostly to store tasks and associated segments to a persistency interface.
struct TaskList {
    
    /// List of tasks
    var tasks: [Task] = []
    
    /// List of task segments registered for the tasks above
    var taskSegments: [TaskSegment] = []
    
    init(tasks: [Task] = [], taskSegments: [TaskSegment] = []) {
        self.tasks = tasks
        self.taskSegments = taskSegments
    }
}
