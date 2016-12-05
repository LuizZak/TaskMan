//
//  EditDateRangeViewController.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 02/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

class EditDateRangeViewController: NSViewController {

    @IBOutlet weak var datePickerStart: NSDatePicker!
    @IBOutlet weak var datePickerEnd: NSDatePicker!
    
    var startDate: Date {
        get {
            _ = view
            return datePickerStart.dateValue
        }
        set {
            _ = view
            datePickerStart.dateValue = newValue
        }
    }
    
    var endDate: Date {
        get {
            _ = view
            return datePickerEnd.dateValue
        }
        set {
            _ = view
            datePickerEnd.dateValue = newValue
        }
    }
    
    var didTapOkCallback: ((EditDateRangeViewController) -> ())?
    
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
        if(datePickerStart.dateValue >= datePickerEnd.dateValue) {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "The start date must come before the end date"
            alert.runModal()
            
            return
        }
        
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
