//
//  TaskSegment.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 16/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

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

// MARK: - Json
extension TaskSegment: ModelObject, IDModelObject {
    init(json: JSON) throws {
        try id = json[JsonKey.id].tryInt()
        try taskId = json[JsonKey.taskId].tryInt()
        try range = json[JsonKey.range].tryParseModel()
    }
    
    func serialize() -> JSON {
        var dict: [JsonKey: Any] = [:]
        
        dict[.id] = id
        dict[.taskId] = taskId
        dict[.range] = range.serialize().object
        
        return dict.mapToJSON()
    }
}

extension TaskSegment {
    
    /// Inner enum containing the JSON key names for the model
    enum JsonKey: String, JSONSubscriptType {
        case id
        case taskId = "task_id"
        case range
        
        var jsonKey: JSONKey {
            return JSONKey.key(self.rawValue)
        }
    }
}
