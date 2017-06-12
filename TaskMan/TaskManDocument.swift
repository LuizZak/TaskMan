//
//  TaskManDocument.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 06/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

class TaskManDocument: NSDocument {
    
    var taskManState = TaskManState(range: Date()...Date().addingTimeInterval(8 * 60 * 60))
    
    override func defaultDraftName() -> String {
        let now = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMdd", options: 0, locale: nil)
        
        return "\(formatter.string(from: now)) Tasks"
    }
    
    override func makeWindowControllers() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: "Document View Controller") as! NSWindowController
        self.addWindowController(windowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        var json = JSON([:])
        let state = taskManState.serialize()
        
        json["state"].object = state.object
        json["version"].int = FileFormatVersion
        
        return try json.rawData(options: .prettyPrinted)
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        var error: NSError? = nil
        var json = JSON(data: data, error: &error)
        if let error = error {
            throw error
        }
        
        guard let version = json["version"].int else {
            throw ReadError.InvalidFormat
        }
        
        // Check conversion
        if(version != FileFormatVersion) {
            let converter = TaskManStateConverter()
            
            if(!converter.canConvertFrom(version: version)) {
                throw ReadError.InvalidVersion
            }
            
            json = try converter.convert(json: json, fromVersion: version)
        }
        
        self.taskManState = try TaskManState(json: json["state"])
    }
    
    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    /// Errors raised during file format reading
    enum ReadError: Error {
        /// Thrown when the file is in an incorrectly formatted type
        case InvalidFormat
        
        /// Thrown when the file is from an unsuported/future/dated version of TaskMan
        case InvalidVersion
    }
}
