//
//  TaskSegment+JSON.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 08/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import SwiftyJSON

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
