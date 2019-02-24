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
    
    var taskManState = TaskManState(range: Date()...Date() + (8 * 60 * 60))
    
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
        let encoder = makeDefaultJSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        
        let data = FileData(version: FileFormatVersion, state: taskManState)
        
        return try encoder.encode(data)
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        var json = try JSON(data: data)
        
        guard let version = json["version"].int else {
            throw ReadError.InvalidFormat
        }
        
        // Check conversion
        if version != FileFormatVersion {
            let converter = TaskManStateConverter()
            
            if !converter.canConvertFrom(version: version) {
                throw ReadError.InvalidVersion
            }
            
            json = try converter.convert(json: json, fromVersion: version)
        }
        
        let decoder = makeDefaultJSONDecoder()
        
        do {
            let fileData = try decoder.decode(FileData.self, from: try json.rawData())
            taskManState = fileData.state
        } catch {
            Swift.print(error)
            throw error
        }
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    /// Errors raised during file format reading
    enum ReadError: Error {
        /// Thrown when the file is in an incorrectly formatted type
        case InvalidFormat
        
        /// Thrown when the file is from an unsuported/future/dated version of TaskMan
        case InvalidVersion
    }
    
    private struct FileData: Codable {
        var version: Int
        var state: TaskManState
    }
}
