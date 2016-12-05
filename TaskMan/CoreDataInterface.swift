//
//  CoreDataInterface.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import AERecord

/// Singleton class used to interface with core data
class CoreDataInterface: NSObject {
    static let sharedInstance = CoreDataInterface()
    
    private override init() {
        super.init()
    }
    
    public func initCoreData() throws {
        try AERecord.loadCoreDataStack()
    }
}
