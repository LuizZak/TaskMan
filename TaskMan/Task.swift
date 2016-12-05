//
//  Task.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 16/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

/// Represents a Task on the system
struct Task {
    
    typealias IDType = Int
    
    /// The task's ID
    var id: IDType
    
    /// A simple name for this task
    var name: String
    
    /// The task's textual description
    var description: String
    
    init(id: IDType) {
        self.id = id
        self.name = ""
        self.description = ""
    }
    
    init(id: IDType, name: String, description: String) {
        self.id = id
        self.name = name
        self.description = description
    }
}

// MARK: - Json
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
