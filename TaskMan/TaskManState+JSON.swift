//
//  TaskManState+JSON.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 08/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import SwiftyJSON

extension TaskManState: ModelObject {
    
    init(json: JSON) throws {
        try taskList = json[JsonKey.taskList].tryParseModel()
        runningSegmentId = try? json[JsonKey.runningSegmentId].tryInt()
        try timeRange = json[JsonKey.timeRange].tryParseModel()
        try creationDate = json[JsonKey.creationDate].tryParseDate(withFormatter: rfc3339DateTimeFormatter)
    }
    
    func serialize() -> JSON {
        var dict: [JsonKey: Any] = [:]
        
        dict[.taskList] = taskList.serialize().object
        dict[.runningSegmentId] = runningSegmentId ?? NSNull()
        dict[.timeRange] = timeRange.serialize().object
        dict[.creationDate] = rfc3339StringFrom(date: creationDate)
        
        return dict.mapToJSON()
    }
}

extension TaskManState {
    
    /// Inner enum containing the JSON key names for the model
    enum JsonKey: String, JSONSubscriptType {
        case taskList = "task_list"
        case runningSegmentId = "running_segment_id"
        case timeRange = "timeRange"
        case creationDate = "creation_date"
        
        var jsonKey: JSONKey {
            return JSONKey.key(self.rawValue)
        }
    }
}
