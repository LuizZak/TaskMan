//
//  TaskList.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

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

// MARK: Json
extension TaskList: JsonInitializable, JsonSerializable {
    
    init(json: JSON) throws {
        try tasks = json[JsonKey.tasks].tryParseModels()
        try taskSegments = json[JsonKey.taskSegments].tryParseModels()
    }
    
    func serialize() -> JSON {
        var dict: [JsonKey: Any] = [:]
        
        dict[.tasks] = tasks.jsonSerialize().map { $0.object }
        dict[.taskSegments] = taskSegments.jsonSerialize().map { $0.object }
        
        return dict.mapToJSON()
    }
}

extension TaskList {
    
    /// Inner enum containing the JSON key names for the model
    enum JsonKey: String, JSONSubscriptType {
        case tasks
        case taskSegments = "task_segments"
        
        var jsonKey: JSONKey {
            return JSONKey.key(self.rawValue)
        }
    }
}
