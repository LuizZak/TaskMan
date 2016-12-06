//
//  ChangeSegmentTaskViewController.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

class ChangeSegmentTaskViewController: NSViewController {
    
    /// The task controller to get the tasks and segment information from
    var taskController: TaskController!
    
    /// The segment to replace the task of
    var segment: TaskSegment!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.title = "Change segment's task";
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let window = self.view.window {
            if let screenSize = window.screen?.frame.size {
                window.setFrameOrigin(NSPoint(x: (screenSize.width - window.frame.size.width) / 2, y: (screenSize.height - window.frame.size.height) / 2))
            }
        }
    }
}

extension ChangeSegmentTaskViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return taskController.currentTasks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let cell = tableView.make(withIdentifier: "textCell", owner: self) as? NSTableCellView else {
            return nil
        }
        
        let task = taskController.currentTasks[row]
        
        cell.textField?.stringValue = task.name
        
        return cell
    }
}

extension ChangeSegmentTaskViewController: NSTableViewDelegate {
    
}
