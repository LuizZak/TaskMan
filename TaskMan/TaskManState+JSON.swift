//
//  TaskManState+JSON.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 08/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

extension TaskManState: ModelObject {
    
    init(json: JSON) throws {
        try taskList = json[JsonKey.taskList].tryParseModel()
        runningSegment = try? json[JsonKey.runningSegment].tryParseModel()
        try timeRange = json[JsonKey.timeRange].tryParseModel()
        try creationDate = json[JsonKey.creationDate].tryParseDate(withFormatter: rfc3339DateTimeFormatter)
    }
    
    func serialize() -> JSON {
        var dict: [JsonKey: Any] = [:]
        
        dict[.taskList] = taskList.serialize().object
        dict[.runningSegment] = runningSegment?.serialize().object ?? NSNull()
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
