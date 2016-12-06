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
        return try taskManState.serialize().rawData()
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        var error: NSError? = nil
        let json = JSON(data: data, error: &error)
        if let error = error {
            throw error
        }
        
        self.taskManState = try TaskManState(json: json)
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

}
