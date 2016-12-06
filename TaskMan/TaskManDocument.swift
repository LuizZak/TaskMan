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
    
    var taskManState = TaskManState(range: DateRange(startDate: Date(),endDate: Date().addingTimeInterval(8 * 60 * 60)))
    
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

    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override func data(ofType typeName: String) throws -> Data {
        var json = JSON([:])
        let state = taskManState.serialize()
        
        json["state"].object = state.object
        json["version"].int = FileFormatVersion
        
        return try json.rawData()
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

/// Private helper class used to help convert files from previous versions of TaskMan
private class TaskManStateConverter {
    
    /// Returns whether the given file version can be converted to the newest compatible format
    func canConvertFrom(version: Int) -> Bool {
        return version == FileFormatVersion
    }
    
    /// Converts the given JSON structure to the newest compatible format
    func convert(json: JSON, fromVersion version: Int) throws -> JSON {
        return json
    }
}
