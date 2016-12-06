//
//  AppDelegate.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 16/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    override init() {
        _ = TaskDocumentController()
        
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ application: NSApplication, willPresentError error: Error) -> Error {
        
        let nsError: NSError = error as NSError
        if (nsError.domain == (TaskManDocument.ReadError.InvalidVersion as NSError).domain) {
            let description = "\(nsError.localizedDescription)\nThe file was created with a future/unsuported version of TaskMan."
            let newError = NSError(domain: "TaskManError", code: 1001, userInfo: [NSLocalizedDescriptionKey: description])
            
            return newError
        }
        
        return error
    }
}

