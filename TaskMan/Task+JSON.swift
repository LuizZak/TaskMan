//
//  Task+JSON.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 08/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import SwiftyJSON

extension Task: ModelObject, IDModelObject {
    
    init(json: JSON) throws {
        try self.id = json[JsonKey.id].tryInt()
        try self.name = json[JsonKey.name].tryString()
        try self.description = json[JsonKey.description].tryString()
    }
    
    func serialize() -> JSON {
        var dict: [JsonKey: Any] = [:]
        
        dict[.id] = id
        dict[.name] = name
        dict[.description] = description
        
        return dict.mapToJSON()
    }
}

extension Task {
    
    /// Inner enum containing the JSON key names for the model
    enum JsonKey: String, JSONSubscriptType {
        case id
        case name
        case description
        
        var jsonKey: JSONKey {
            return JSONKey.key(self.rawValue)
        }
    }
}
