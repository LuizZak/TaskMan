//
//  TaskList+JSON.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 10/06/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import SwiftyJSON

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
