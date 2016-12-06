//
//  TaskDocumentController.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 06/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

class TaskDocumentController: NSDocumentController {
    override func makeUntitledDocument(ofType typeName: String) throws -> NSDocument {
        let doc = TaskManDocument()
        
        return doc
    }
}
