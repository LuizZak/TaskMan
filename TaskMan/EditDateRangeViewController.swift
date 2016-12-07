//
//  EditDateRangeViewController.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 02/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

class EditDateRangeViewController: NSViewController, NSTabViewDelegate, NSTextFieldDelegate {
    
    @IBOutlet weak var datePickerStart: NSDatePicker!
    @IBOutlet weak var datePickerEnd: NSDatePicker!
    @IBOutlet weak var datePickerStartRange: NSDatePicker!
    @IBOutlet weak var txtDuration: NSTextField!
    @IBOutlet weak var tabView: NSTabView!
    
    private(set) var startDate: Date = Date()
    private(set) var endDate: Date = Date()
    
    var didTapOkCallback: ((EditDateRangeViewController) -> ())?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        txtDuration.delegate = self
        txtDuration.drawsBackground = true
        
        // Centralize on screen
        if let window = self.view.window {
            if let screenSize = window.screen?.frame.size {
                window.setFrameOrigin(NSPoint(x: (screenSize.width - window.frame.size.width) / 2, y: (screenSize.height - window.frame.size.height) / 2))
            }
        }
    }
    
    func setDateRange(dateRange: DateRange) {
        startDate = dateRange.startDate
        endDate = dateRange.endDate
        
        updateDisplay()
    }
    
    @IBAction func didTapOk(_ sender: NSButton) {
        guard let callback = didTapOkCallback else {
            dismiss(self)
            return
        }
        
        // Validate duration text, if that tab's chosen
        if(tabView.selectedTabViewItem == tabView.tabViewItems[1]) {
            if(!isDurationTextValid()) {
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Please input a valid, positive time range for the duration."
                alert.runModal()
                return
            }
        }
        
        updateDatesFromPickers()
        
        if(startDate >= endDate) {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "The start date must come before the end date"
            alert.runModal()
            
            return
        }
        
        callback(self)
    }
    
    @IBAction func didUpdatePickerDate(_ sender: NSDatePicker) {
        updateDatesFromPickers()
    }
    
    @IBAction func didTapCancel(_ sender: NSButton) {
        dismiss(self)
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        // Try to evaluate time interval from text field
        if(!isDurationTextValid()) {
            txtDuration.toolTip = "The given text is not a valid time string"
            txtDuration.backgroundColor = NSColor(calibratedRed: 1, green: 0.75, blue: 0.75, alpha: 1)
        } else {
            txtDuration.backgroundColor = NSColor.clear
        }
    }
    
    private func updateDatesFromPickers() {
        // Update before returning
        if(tabView.selectedTabViewItem == tabView.tabViewItems.first) {
            // Start/End date
            startDate = datePickerStart.dateValue
            endDate = datePickerEnd.dateValue
        } else {
            // Start/Duration
            startDate = datePickerStartRange.dateValue
            
            // Evaluate from text
            do {
                let value = try Evaluator.evaluate(expression: txtDuration.stringValue)
                if case .time(let interval) = value {
                    endDate = startDate.addingTimeInterval(interval)
                } else {
                    endDate = startDate
                }
            } catch {
                endDate = startDate
            }
        }
    }
    
    private func isDurationTextValid() -> Bool {
        if case .some(.time(let time)) = try? Evaluator.evaluate(expression: txtDuration.stringValue), time >= 0 {
            return true
        }
        
        return false
    }
    
    func updateDisplay() {
        _ = view // Force view loading
        
        if(tabView.selectedTabViewItem == tabView.tabViewItems.first) {
            // Start/End date
            datePickerStart.dateValue = startDate
            datePickerEnd.dateValue = endDate
        } else {
            // Start/Duration
            datePickerStartRange.dateValue = startDate
            
            // Figure out date for duration picker
            let interval = endDate.timeIntervalSince(startDate)
            
            txtDuration.stringValue = formatTimestampCompact(interval)
        }
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        // Update dates
        updateDisplay()
    }
}
