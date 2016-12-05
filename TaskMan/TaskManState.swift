//
//  TaskManState.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

/// Basic structure that bundles a TaskMan state
struct TaskManState {
    
    /// The task list associated with this state, containing the tasks and
    /// segments stored
    var taskList: TaskList
    
    /// A currently running segment, if any.
    var runningSegment: TaskSegment?
    
    /// The date range for displaying the default timeline with
    var timeRange: DateRange
    
    /// The creation date for this state
    var creationDate: Date
    
    /// Inits a TaskMan state with an empty set of data, and a creation date set to this moment
    init(range: DateRange) {
        taskList = TaskList()
        timeRange = range
        creationDate = Date()
    }
}

// MARK: - Json

extension TaskManState: ModelObject {
    
    init(json: JSON) throws {
        try taskList = json[JsonKey.taskList].tryParseModel()
        try runningSegment = json[JsonKey.runningSegment].tryParseModel(withType: TaskSegment.self)
        try timeRange = json[JsonKey.timeRange].tryParseModel()
        try creationDate = json[JsonKey.creationDate].tryParseDate(withFormatter: rfc3339DateTimeFormatter)
    }
    
    func serialize() -> JSON {
        var dict: [JsonKey: Any] = [:]
        
        dict[.taskList] = taskList.serialize().object
        dict[.runningSegment] = runningSegment?.serialize() ?? NSNull()
        dict[.timeRange] = timeRange.serialize().object
        dict[.creationDate] = rfc3339StringFrom(date: creationDate)
        
        return dict.mapToJSON()
    }
}

extension TaskManState {
    
    /// Inner enum containing the JSON key names for the model
    enum JsonKey: String, JSONSubscriptType {
        case taskList = "task_list"
        case runningSegment = "running_segment"
        case timeRange = "timeRange"
        case creationDate = "creation_date"
        
        var jsonKey: JSONKey {
            return JSONKey.key(self.rawValue)
        }
    }
}

