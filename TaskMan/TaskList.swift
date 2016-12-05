//
//  TaskList.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

/// Describes a collection of tasks.
/// Used mostly to store tasks and associated segments to a persistency interface.
struct TaskList {
    
    /// List of tasks
    var tasks: [Task] = []
    
    /// Display name for this task list
    var name: String
    
    /// Datetime at which this task list was created
    var creationDate: Date
    
    /// Last date at which this task list was modified
    var updateDate: Date
}
