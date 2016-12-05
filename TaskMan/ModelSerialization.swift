//
//  ModelSerialization.swift
//  RESS
//
//  Created by Luiz Fernando Silva on 17/07/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

/// Serializes the given array of model objects into an array of JSON objects
func jsonSerialize<T: JsonSerializable, S: Sequence>(models: S) -> [JSON] where S.Iterator.Element == T {
    return models.jsonSerialize()
}

/// Unserializes the given array of JSON objects into a type provided through the generic T argument.
/// In case any of the objects being unserialized fails to initialize, a JSONError error is raised
func jsonUnserializeStrict<T: JsonInitializable, S: Sequence>(_ source: S, type: T.Type) throws -> [T] where S.Iterator.Element == JSON {
    return try source.jsonUnserializeStrict(withType: type)
}

/// Unserializes this array of JSON objects into a type provided through the generic T argument.
/// In case any of the objects being unserialized fails to initialize, a nil value is returned
func jsonUnserializeOptional<T: JsonInitializable, S: Sequence>(_ source: S, type: T.Type) -> [T]? where S.Iterator.Element == JSON {
    return source.jsonUnserializeOptional(withType: type)
}

/// Unserializes the given array of JSON objects into a type provided through the generic T argument.
/// This version returns an array of all successful initializations, ignoring any failed initializations
func jsonUnserialize<T: JsonInitializable, S: Sequence>(_ source: S, type: T.Type) -> [T] where S.Iterator.Element == JSON {
    return source.jsonUnserialize(withType: type)
}

extension Sequence where Iterator.Element == JSON {
    
    /// Unserializes this array of JSON objects into a type provided through the generic T argument.
    /// In case any of the objects being unserialized fails to initialize, a JSONError error is raised
    func jsonUnserializeStrict<T: JsonInitializable>(withType type: T.Type) throws -> [T] {
        var output: [T] = []
        
        for dictionary in self {
            var unserialized: T!
            
            do {
                try autoreleasepool {
                    unserialized = try T(json: dictionary)
                }
            } catch {
                print("Error while trying to parse \(T.self) objects: \(error)")
                
                throw error
            }
            
            output.append(unserialized)
        }
        
        return output
    }
    
    /// Unserializes this array of JSON objects into a type provided through the generic T argument.
    /// In case any of the objects being unserialized fails to initialize, a nil value is returned
    func jsonUnserializeOptional<T: JsonInitializable>(withType type: T.Type) -> [T]? {
        return try? jsonUnserializeStrict(withType: type)
    }
    
    /// Unserializes this array of JSON objects into a type provided through the generic T argument.
    /// This version returns an array of all successful initializations, ignoring any failed initializations
    func jsonUnserialize<T: JsonInitializable>(withType type: T.Type) -> [T] {
        var output: [T] = []
        
        for dictionary in self {
            var unserialized: T?
            autoreleasepool {
                unserialized = try? T(json: dictionary)
            }
            
            if let item = unserialized {
                output.append(item)
            }
        }
        
        return output
    }
}

extension Sequence where Iterator.Element: JsonSerializable {
    /// Serializes this sequence of model objects into an array of JSON objects
    func jsonSerialize() -> [JSON] {
        return self.map { $0.serialize() }
    }
}
