//
//  ChangeSegmentTaskViewController.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

class ChangeSegmentTaskViewController: NSViewController {
    
    @IBOutlet weak var txtTaskName: NSTextField!
    @IBOutlet weak var btnOk: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    
    /// The task controller to get the tasks and segment information from
    var taskController: TaskController!
    
    /// The segment to replace the task of
    var segment: TaskSegment!
    
    /// Callback to fire when the user has chosen a task
    var callback: ((ChangeSegmentTaskViewController) -> ())?
    
    /// Gets the currently selected task
    fileprivate(set) var selectedTask: Task?
    
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
        
        // Fetch the name of the task of the current segment
        if let task = taskController.getTask(withId: segment.taskId) {
            txtTaskName.stringValue = task.name
        } else {
            txtTaskName.stringValue = "< None >"
        }
    }
    
    @IBAction func didTapOk(_ sender: NSButton) {
        if let callback = callback {
            callback(self)
        } else {
            self.dismiss(self)
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.dismiss(self)
    }
}

extension ChangeSegmentTaskViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return taskController.currentTasks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "textCell"), owner: self) as? NSTableCellView else {
            return nil
        }
        
        let task = taskController.currentTasks[row]
        
        cell.textField?.stringValue = task.name
        cell.objectValue = task
        
        return cell
    }
}

extension ChangeSegmentTaskViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        selectedTask = taskController.currentTasks[row]
        
        btnOk.isEnabled = true
        
        return true
    }
}
