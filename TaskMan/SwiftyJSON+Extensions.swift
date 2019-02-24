//
//  SwiftyJSON+Extensions.swift
//  RESS
//
//  Created by Luiz Fernando Silva on 27/08/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSON {
    
    /// Returns an optional Int value depending on the current value of the JSON object.
    /// Returns an integer if the value is an int or an int-convertible string; nil otherwise
    var intConvertible: Int? {
        get {
            switch(type) {
            case .number:
                return int
                
            case .string:
                return string.flatMap { Int($0) }
                
            default: return nil
            }
        }
    }
    
    /// Returns an optional Double value depending on the current value of the JSON object.
    /// Returns an double if the value is an double or a double-convertible string; nil otherwise
    var doubleConvertible: Double? {
        get {
            switch(type) {
            case .number:
                return double
                
            case .string:
                return string.flatMap { Double($0) }
                
            default: return nil
            }
        }
    }
}

public enum JSONError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    case InvalidType(message: String)
    case UnexpectedType(expected: Type, received: Type)
    case ModelInitializeError(message: String, error: Error?, file: String, line: Int)
    case ComposedError(error: Error, file: String, line: Int)
    
    public var description: String {
        switch (self) {
        case .InvalidType(let msg):
            return "InvalidType: \(msg)"
        case .UnexpectedType(let exp, let rec):
            return "UnexpectedType: Expected \(exp) received \(rec)"
        case .ModelInitializeError(let message, let error, let file, let line):
            if let error = error {
                return "\(message) on file \(file) line \(line): \(error)"
            } else {
                return "\(message) on file \(file) line \(line)"
            }
        case .ComposedError(let error, let file, let line):
            return "\(error) on file \(file) line \(line)"
        }
    }
    
    public var debugDescription: String {
        return description
    }
}

// Extension for performing error-throwing JSON parsing.
// Used mostly for failing during model creations nicely using do { } catch { } statements
public extension JSON {
    
    func tryString(file: String = #file, line: Int = #line) throws -> String {
        if let value = self.string {
            return value
        }
        
        throw composeError(self.error ?? JSONError.UnexpectedType(expected: Type.string, received: self.type), file: file, line: line)
    }
    
    /// Tries to parse the contents of this JSON object into a string-valued Swift enum instance
    ///
    /// - remark:
    /// `type: T.Type = T.self` allows the type of T to be inferred by the usage of this method, in some cases.
    /// That means that a line such as:
    ///
    /// ```
    /// var option: SomeEnum = try json.tryParseEnum()
    /// ```
    ///
    /// would infer T to be `SomeEnum`, without the need to specify the `type` parameter explicitly, because the required
    /// return type is `SomeEnum` since we are intializing a `SomeEnum`-typed variable.
    func tryParseEnum<T: RawRepresentable>(withType type: T.Type = T.self, file: String = #file, line: Int = #line) throws -> T where T.RawValue == String {
        guard let value = self.string else {
            throw composeError(self.error ?? JSONError.UnexpectedType(expected: Type.string, received: self.type), file: file, line: line)
        }
        
        if let result = T(rawValue: value) {
            return result
        }
        
        throw composeError(self.error ?? JSONError.InvalidType(message: "Could not parse enum \(T.self) out of value '\(value)'"), file: file, line: line)
    }
    
    /// Tries to parse the contents of this JSON object into an integer-valued Swift enum instance
    ///
    /// - remark:
    /// `type: T.Type = T.self` allows the type of T to be inferred by the usage of this method, in some cases.
    /// That means that a line such as:
    ///
    /// ```
    /// var option: SomeEnum = try json.tryParseEnum()
    /// ```
    ///
    /// would infer T to be `SomeEnum`, without the need to specify the `type` parameter explicitly, because the required
    /// return type is `SomeEnum` since we are intializing a `SomeEnum`-typed variable.
    func tryParseEnum<T: RawRepresentable>(withType type: T.Type = T.self, file: String = #file, line: Int = #line) throws -> T where T.RawValue == Int {
        guard let value = self.int else {
            throw composeError(self.error ?? JSONError.UnexpectedType(expected: Type.number, received: self.type), file: file, line: line)
        }
        
        if let result = T(rawValue: value) {
            return result
        }
        
        throw composeError(self.error ?? JSONError.InvalidType(message: "Could not parse enum \(T.self) out of value \(value)"), file: file, line: line)
    }
    
    func tryInt(file: String = #file, line: Int = #line) throws -> Int {
        if let value = self.intConvertible {
            return value
        }
        
        throw composeError(self.error ?? JSONError.UnexpectedType(expected: Type.number, received: self.type), file: file, line: line)
    }
    
    func tryDouble(file: String = #file, line: Int = #line) throws -> Double {
        if let value = self.doubleConvertible {
            return value
        }
        
        throw composeError(self.error ?? JSONError.UnexpectedType(expected: Type.number, received: self.type), file: file, line: line)
    }
    
    func tryBool(file: String = #file, line: Int = #line) throws -> Bool {
        if let value = self.bool {
            return value
        }
        
        throw composeError(self.error ?? JSONError.UnexpectedType(expected: Type.bool, received: self.type), file: file, line: line)
    }
    
    func tryParseDate(withFormatter formatter: DateFormatter, file: String = #file, line: Int = #line) throws -> Date {
        guard let string = self.string else {
            throw composeError(self.error ?? JSONError.UnexpectedType(expected: Type.string, received: self.type), file: file, line: line)
        }
        
        if let value = formatter.date(from: string) {
            return value
        }
        
        throw composeError(self.error ?? JSONError.InvalidType(message: "Could not parse '\(formatter.dateFormat!)' date out of value '\(string)'"), file: file, line: line)
    }
}

extension JSON {
    
    /// Tries to parse the contents of this JSON object into an instance of a JsonInitializable object.
    ///
    /// - remark:
    /// `type: T.Type = T.self` allows the type of T to be inferred by the usage of this method, in some cases.
    /// That means that a line such as:
    ///
    /// ```
    /// var user: User = try json.tryParseModel()
    /// ```
    ///
    /// would infer T to be `User`, without the need to specify the `type` parameter explicitly, because the required
    /// return type is `User` since we are intializing a `User`-typed variable.
    func tryParseModel<T: JsonInitializable>(withType type: T.Type = T.self, file: String = #file, line: Int = #line) throws -> T {
        do {
            return try type.init(json: self)
        } catch {
            throw modelInitializeError(type, error: error, file: file, line: line)
        }
    }
    
    /// Tries to parse the contents of this JSON object into a collection of JsonInitializable objects.
    ///
    /// - remark:
    /// `type: T.Type = T.self` allows the type of T to be inferred by the usage of this method, in some cases.
    /// That means that a line such as:
    ///
    /// ```
    /// var users: [User] = try json.tryParseModels()
    /// ```
    ///
    /// would infer T to be `User`, without the need to specify the `type` parameter explicitly, because the required
    /// return type is `[User]` since we are intializing a `[User]`-typed variable.
    func tryParseModels<T: JsonInitializable>(withType type: T.Type = T.self, file: String = #file, line: Int = #line) throws -> [T] {
        if let array = try self.array?.jsonUnserializeStrict(withType: type) {
            return array
        }
        
        throw composeError(self.error ?? JSONError.UnexpectedType(expected: Type.array, received: self.type), file: file, line: line)
    }
}

// Composes a given error with a wrapper that contains
private func composeError(_ error: Error, file: String, line: Int) -> JSONError {
    return JSONError.ComposedError(error: error, file: (file as NSString).lastPathComponent, line: line)
}

private func modelInitializeError(_ type: Any.Type, error: Error, file: String, line: Int) -> JSONError {
    return JSONError.ModelInitializeError(message: "Could not initialize model of type \(type)", error: error, file: (file as NSString).lastPathComponent, line: line)
}
