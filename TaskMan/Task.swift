//
//  Task.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 16/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

/// Represents a Task on the system
struct Task: Codable {
    
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
