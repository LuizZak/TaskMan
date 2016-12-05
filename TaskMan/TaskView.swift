//
//  TaskView.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 20/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

protocol TaskViewDelegate: class {
    func didTapRemoveButtonOnTaskView(_ taskView: TaskView)
    
    func didTapStartStopButtonOnTaskView(_ taskView: TaskView)
    
    func didTapSegmentListButtonOnTaskView(_ taskView: TaskView)
}

extension TaskViewDelegate {
    func didTapRemoveButtonOnTaskView(_ taskView: TaskView) { }
    func didTapStartStopButtonOnTaskView(_ taskView: TaskView) { }
    func didTapSegmentListButtonOnTaskView(_ taskView: TaskView) { }
}

class TaskView: NSView {
    
    @IBOutlet var txtName: NSTextField!
    @IBOutlet var lblRuntime: NSTextField!
    @IBOutlet var viewTimeline: TimelineView!
    @IBOutlet var btnStartStop: NSButton!
    @IBOutlet var btnSegmentList: NSButton!
    @IBOutlet var txtDescription: NSTextView!
    @IBOutlet var view: NSView!
    
    weak var delegate: TaskViewDelegate?
    
    /// Gets or sets the display state for this task view
    var displayState: State = .Stopped {
        didSet {
            // Update image
            let image: NSImage?
            switch(displayState) {
            case .Stopped:
                image = NSImage(named: "NSRightFacingTriangleTemplate")
                layer?.borderColor = NSColor.clear.cgColor
            case .Running:
                image = NSImage(named: "NSMenuOnStateTemplate")
                layer?.borderColor = NSColor.green.withAlphaComponent(0.3).cgColor
            }
            
            btnStartStop.image = image
        }
    }
    
    var taskId: Task.IDType
    
    init(taskId: Task.IDType, frame frameRect: NSRect) {
        self.taskId = taskId
        
        super.init(frame: frameRect)
        
        self.wantsLayer = true
        self.layer?.borderWidth = 2
        
        Bundle.main.loadNibNamed("TaskView", owner: self, topLevelObjects: nil)
        
        self.addSubview(view)
    }
    
    required init?(coder: NSCoder) {
        self.taskId = 0
        
        super.init(coder: coder)
    }
    
    @IBAction func didTapStartStopButton(_ sender: NSButton) {
        delegate?.didTapStartStopButtonOnTaskView(self)
    }
    
    @IBAction func didTapRemoveButton(_ sender: NSButton) {
        delegate?.didTapRemoveButtonOnTaskView(self)
    }
    
    @IBAction func didTapSegmentListButton(_ sender: NSButton) {
        delegate?.didTapSegmentListButtonOnTaskView(self)
    }
    
    enum State {
        case Running
        case Stopped
    }
}
