//
//  EditDateViewController.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

class EditDateViewController: NSViewController {

    @IBOutlet weak var datePicker: NSDatePicker!
    
    var date: Date {
        get {
            _ = view
            return datePicker.dateValue
        }
        set {
            _ = view
            datePicker.dateValue = newValue
        }
    }
    
    var didTapOkCallback: ((EditDateViewController) -> ())?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Centralize on screen
        if let window = self.view.window {
            if let screenSize = window.screen?.frame.size {
                window.setFrameOrigin(NSPoint(x: (screenSize.width - window.frame.size.width) / 2, y: (screenSize.height - window.frame.size.height) / 2))
            }
        }
    }
    
    @IBAction func didTapOk(_ sender: NSButton) {
        guard let callback = didTapOkCallback else {
            dismiss(self)
            return
        }
        
        callback(self)
    }
    
    @IBAction func didTapCancel(_ sender: NSButton) {
        dismiss(self)
    }
    
}
