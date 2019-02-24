//
//  IDModelObject.swift
//  RESS
//
//  Created by Luiz Fernando Silva on 17/02/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

/// Protocol to be implemented by model objects identifiable by a unique ID
protocol IDModelObject: Hashable {
    associatedtype IdentifierType = Int
    
    /// Gets a unique identifier for this model object
    var id: IdentifierType { get }
}

/// Default implementation of Hashable for an IDModelObject which has a Hashable key type - returns the hash of the object's ID
extension IDModelObject where IdentifierType: Hashable {
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}

/// Protocol to be implemented by model objects that conform to a simple { id, name } model structure.
/// This model type is also sortable by name by default.
protocol NamedIDModelObject: IDModelObject, Comparable {
    
    /// Gest the display name of this model
    var name: String { get }
    
    init(id: IdentifierType, name: String)
}

/// Comparable extension that is used to sort for interface display
func <<T: NamedIDModelObject>(lhs: T, rhs: T) -> Bool {
    return lhs.name < rhs.name
}

// Extension for quick initialization of simple named model objects by providing a JSON with ID and Name, where the ID is an integer
extension ModelObject where Self: NamedIDModelObject, Self.IdentifierType == Int {
    init(json: JSON) throws {
        try self.init(id: json["id"].tryInt(), name: json["name"].tryString())
    }
    
    func serialize() -> JSON {
        return ["id": id, "name": name]
    }
}

// Extension for quick initialization of simple named model objects by providing a JSON with ID and Name, where the ID is a string
extension ModelObject where Self: NamedIDModelObject, Self.IdentifierType == String {
    init(json: JSON) throws {
        try self.init(id: json["id"].tryString(), name: json["name"].tryString())
    }
    
    func serialize() -> JSON {
        return ["id": id, "name": name]
    }
}

// Extension that speeds up comparisions of model objects by first checking if their IDs match
// before making a full value-wise comparision
extension ModelObject where Self: IDModelObject, Self.IdentifierType: Equatable {
    func equalsTo(_ other: Self) -> Bool {
        return self.id == other.id && self.serialize() == other.serialize()
    }
}

// Extension that speeds up comparisions of model objects by checking ID and name directly.
// No further comparision is made, as NamedIDModelObjects are assumed to contain only an id and name field.
extension ModelObject where Self: NamedIDModelObject, Self.IdentifierType: Equatable {
    func equalsTo(_ other: Self) -> Bool {
        return self.id == other.id && self.name == other.name
    }
}
