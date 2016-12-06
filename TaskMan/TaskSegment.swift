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
}

extension DateRange: Equatable {
    static func ==(lhs: DateRange, rhs: DateRange) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
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

extension DateRange: JsonInitializable, JsonSerializable {
    init(json: JSON) throws {
        try self.startDate = json[JsonKey.startDate].tryParseDate(withFormatter: rfc3339DateTimeFormatter)
        try self.endDate = json[JsonKey.endDate].tryParseDate(withFormatter: rfc3339DateTimeFormatter)
    }
    
    func serialize() -> JSON {
        var dict: [JsonKey: Any] = [:]
        
        dict[.startDate] = rfc3339StringFrom(date: startDate)
        dict[.endDate] = rfc3339StringFrom(date: endDate)
        
        return dict.mapToJSON()
    }
}

extension DateRange {
    
    /// Inner enum containing the JSON key names for the model
    enum JsonKey: String, JSONSubscriptType {
        case startDate = "start_date"
        case endDate = "end_date"
        
        var jsonKey: JSONKey {
            return JSONKey.key(self.rawValue)
        }
    }
}
