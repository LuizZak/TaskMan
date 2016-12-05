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
    
    /// Display name for this task list
    var name: String
    
    /// Datetime at which this task list was created
    var creationDate: Date
    
    /// Last date at which this task list was modified
    var updateDate: Date
    
    /// Convenience initializer that inits an empty task list, with a creation/update date set to now
    init(name: String) {
        self.name = name
        self.creationDate = Date()
        self.updateDate = self.creationDate
    }
}

// MARK: Json
extension TaskList: JsonInitializable, JsonSerializable {
    
    init(json: JSON) throws {
        try tasks = json[JsonKey.tasks].tryParseModels()
        try taskSegments = json[JsonKey.taskSegments].tryParseModels()
        try name = json[JsonKey.name].tryString()
        try creationDate = json[JsonKey.creationDate].tryParseDate(withFormatter: rfc3339DateTimeFormatter)
        try updateDate = json[JsonKey.updateDate].tryParseDate(withFormatter: rfc3339DateTimeFormatter)
    }
    
    func serialize() -> JSON {
        var dict: [JsonKey: Any] = [:]
        
        dict[.tasks] = tasks.jsonSerialize().map { $0.object }
        dict[.taskSegments] = taskSegments.jsonSerialize().map { $0.object }
        dict[.name] = name
        dict[.creationDate] = rfc3339StringFrom(date: creationDate)
        dict[.updateDate] = rfc3339StringFrom(date: updateDate)
        
        return dict.mapToJSON()
    }
}

extension TaskList {
    
    /// Inner enum containing the JSON key names for the model
    enum JsonKey: String, JSONSubscriptType {
        case tasks
        case taskSegments = "task_segments"
        case name
        case creationDate = "creation_date"
        case updateDate = "update_date"
        
        var jsonKey: JSONKey {
            return JSONKey.key(self.rawValue)
        }
    }
}
