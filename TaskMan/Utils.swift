//
//  Utils.swift
//  RESS
//
//  Created by Luiz Fernando Silva on 17/06/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SystemConfiguration

// A set of useful, general helper methods that build on top of Swift's own standard lib, Foundation, UIKit and a few
// other internal, default iOS frameworks.
// This file is carried over from previous projects, please refrain from adding project-specific code on this file
// and favor placing such code in separate '-Util.swift' files.

/// Swift version of Objective-C's @synchronized statement.
/// Do note that differently from Obj-C's version, this closure-based version consumes
/// any 'return/continue/break' statements without affecting the parent function it is
/// enclosed in
func synchronized<T>(lock: AnyObject, closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)
    }
    
    return try closure()
}

/// Appends a given element `rhs` into the collection `lhs`
/// Usage: `array += element`
public func +=<U: RangeReplaceableCollection>(lhs: inout U, rhs: U.Iterator.Element) {
    lhs.append(rhs)
}

/// Removes a given equatable element `rhs` into the collection `lhs`
/// Usage: `array -= element`
public func -=<U: RangeReplaceableCollection>(lhs: inout U, rhs: U.Iterator.Element) where U.Iterator.Element: Equatable {
    lhs.remove(rhs)
}

/// Errors thrown in sequence methods
enum SequenceError: Error {
    /// Error thrown when an item was not found in a method requiring at least one item found
    case NotFound
}

/// Set of helper collection searching functions inspired on .NET's LINQ
extension Sequence {
    // MARK: Helper collection searching methods
    
    /// Returns the last item in the sequence that when passed through `compute` returns true.
    /// In case an item is not found, SequenceError.NotFound is thrown
    func last(where compute: (Iterator.Element) throws -> Bool) throws -> Iterator.Element {
        var last: Iterator.Element?
        for item in self {
            if(try compute(item)) {
                last = item
            }
        }
        
        if let last = last {
            return last
        }
        
        throw SequenceError.NotFound
    }
    
    // MARK: Helper collection checking methods
    
    /// Returns true if any of the elements in this sequence return true when passed through `compute`.
    /// Succeeds fast on the first item that returns true
    func any(compute: (Iterator.Element) throws -> Bool) rethrows -> Bool {
        for item in self {
            if(try compute(item)) {
                return true
            }
        }
        
        return false
    }
    
    /// Returns true if all of the elements in this sequence return true when passed through `compute`.
    /// Fails fast on the first item that returns false
    func all(compute: (Iterator.Element) throws -> Bool) rethrows -> Bool {
        for item in self {
            if(try !compute(item)) {
                return false
            }
        }
        
        return true
    }
    
    /// Returns the number of objects in this array that return true when passed through `compute`.
    func count(compute: (Iterator.Element) throws -> Bool) rethrows -> Int {
        var count = 0
        
        for item in self {
            if(try compute(item)) {
                count += 1
            }
        }
        
        return count
    }
    
    /// Returns a dictionary containing elements grouped by a specified key
    /// Note that the 'key' closure is required to always return the same T key for the same value passed in, so values can be grouped correctly
    func groupBy<T: Hashable>(key: (Iterator.Element) -> T) -> [T: [Iterator.Element]] {
        var dict: [T: [Iterator.Element]] = [:]
        
        for item in self {
            let field = key(item)
            
            if dict[field]?.append(item) == nil {
                dict[field] = [item]
            }
        }
        
        return dict
    }
    
    /// Returns a dictionary containing elements grouped by a specified key, applying a trasnform on the elements along the way.
    /// Note that the 'key' closure is required to always return the same T key for the same value passed in, so values can be grouped correctly.
    /// The transform can be used to manipulate values so that keys are removed from the resulting values on the arrays of each dictionary entry
    func groupBy<T: Hashable, U>(key: (Iterator.Element) -> T, transform: (Iterator.Element) -> U) -> [T: [U]] {
        var dict: [T: [U]] = [:]
        
        for item in self {
            let field = key(item)
            
            let newItem = transform(item)
            
            if dict[field]?.append(newItem) == nil {
                dict[field] = [newItem]
            }
        }
        
        return dict
    }
}

extension Sequence where Iterator.Element: Equatable {
    /// Returns the count of values in this sequence type that equal the given `value` element
    func count(value: Iterator.Element) -> Int {
        return count { $0 == value }
    }
}

extension RangeReplaceableCollection {
    /// Removes an item from the collection, usign the given compute closure to specify which item to remove
    @discardableResult
    mutating func removeFirst(where compute: (Self.Iterator.Element) throws -> Bool) rethrows -> Iterator.Element? {
        if let index = try self.index(where: compute) {
            return self.remove(at: index)
        }
        
        return nil
    }
    
    /// Removes all items from the collection, usign the given compute closure to specify which items to remove.
    /// The method also returns a list of all items that where removed on the operation
    @discardableResult
    mutating func remove(where compute: (Self.Iterator.Element) throws -> Bool) rethrows -> [Iterator.Element] {
        var removed: [Iterator.Element] = []
        while let index = try self.index(where: compute) {
            removed.append(self.remove(at: index))
        }
        return removed
    }
}

extension RangeReplaceableCollection where Iterator.Element: Equatable {
    /// Removes a given element from this collection, using the element's equality check to determine the first match to remove
    mutating func remove(_ object: Self.Iterator.Element) {
        self.removeFirst { $0 == object }
    }
}

