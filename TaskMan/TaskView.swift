//
//  TaskView.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 20/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

protocol TaskViewDelegate: class {
    func didTapRemoveButton(onTaskView taskView: TaskView)
    
    func didTapStartStopButton(onTaskView taskView: TaskView)
    
    func didTapSegmentListButton(onTaskView taskView: TaskView)
    
    func didRightClickRuntimeLabel(onTaskView taskView: TaskView, withGesture gesture: NSClickGestureRecognizer)
    
    /// Called to notify the user has changed the text of the namefield for a task view
    func taskView(_ taskView: TaskView, didUpdateName name: String)
    
    /// Called to notify the user has changed the text of the description for a task view
    func taskView(_ taskView: TaskView, didUpdateDescription description: String)
    
    /// Called when a task view has detected a drag and drop operation with a segment over itself, and the dragging operation mask to use.
    /// Returning false blocks the drag operation.
    /// May be called multiple times during a drag operation.
    /// Default implementation returns false and an empty NSDragOperation
    func taskView(_ taskView: TaskView, allowSegmentDrop segment: TaskSegment, withDragInfo dragInfo: NSDraggingInfo) -> (Bool, NSDragOperation)
    
    /// Called when the user has dropped a segment over the area of the task view.
    /// The boolean value returns whether to accept the drag operation.
    /// Default implementation returns false
    func taskView(_ taskView: TaskView, didDropSegment segment: TaskSegment, withDragInfo dragInfo: NSDraggingInfo) -> Bool
}

extension TaskViewDelegate {
    func didTapRemoveButton(onTaskView taskView: TaskView) { }
    func didTapStartStopButton(onTaskView taskView: TaskView) { }
    func didTapSegmentListButton(onTaskView taskView: TaskView) { }
    func didRightClickRuntimeLabel(onTaskView taskView: TaskView, withGesture gesture: NSClickGestureRecognizer) { }
    
    func taskView(_ taskView: TaskView, didUpdateName name: String) { }
    func taskView(_ taskView: TaskView, didUpdateDescription description: String) { }
    
    func taskView(_ taskView: TaskView, allowSegmentDrop segment: TaskSegment, withDragInfo dragInfo: NSDraggingInfo) -> (Bool, NSDragOperation) {
        return (false, NSDragOperation())
    }
    func taskView(_ taskView: TaskView, didDropSegment segment: TaskSegment, withDragInfo dragInfo: NSDraggingInfo) -> Bool {
        return false
    }
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
    var displayState: State = .stopped {
        didSet {
            // Update image
            let image: NSImage?
            switch(displayState) {
            case .stopped:
                image = NSImage(named: "NSRightFacingTriangleTemplate")
                layer?.borderColor = NSColor.clear.cgColor
            case .running:
                image = NSImage(named: "NSMenuOnStateTemplate")
                layer?.borderColor = NSColor.green.withAlphaComponent(0.3).cgColor
            }
            
            btnStartStop.image = image
        }
    }
    
    var dragAndDropDisplayState: DragAndDropState = .none {
        didSet {
            needsDisplay = true
        }
    }
    
    var taskId: Task.IDType
    
    init(taskId: Task.IDType, frame frameRect: NSRect) {
        self.taskId = taskId
        
        super.init(frame: frameRect)
        
        self.wantsLayer = true
        self.layer?.borderWidth = 2
        self.layer?.masksToBounds = false
        
        Bundle.main.loadNibNamed("TaskView", owner: self, topLevelObjects: nil)
        
        self.addSubview(view)
        
        self.registerForDraggedTypes([SegmentDragItemType, NSPasteboard.PasteboardType.string])
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(TaskView.didClickRuntimeLabel(_:)))
        clickGesture.buttonMask = 0x2
        lblRuntime.addGestureRecognizer(clickGesture)
    }
    
    required init?(coder: NSCoder) {
        self.taskId = 0
        
        super.init(coder: coder)
    }
    
    @IBAction func didTapStartStopButton(_ sender: NSButton) {
        delegate?.didTapStartStopButton(onTaskView: self)
    }
    
    @IBAction func didTapRemoveButton(_ sender: NSButton) {
        delegate?.didTapRemoveButton(onTaskView: self)
    }
    
    @IBAction func didTapSegmentListButton(_ sender: NSButton) {
        delegate?.didTapSegmentListButton(onTaskView: self)
    }
    @objc func didClickRuntimeLabel(_ gesture: NSClickGestureRecognizer) {
        delegate?.didRightClickRuntimeLabel(onTaskView: self, withGesture: gesture)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let object = obj.object as? NSTextField, object == txtName {
            delegate?.taskView(self, didUpdateName: txtName.stringValue)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        switch(dragAndDropDisplayState) {
        case .accepted:
            
            NSColor.selectedControlColor.set()
            
            let path = NSBezierPath(rect: bounds.insetBy(dx: 2, dy: 2))
            path.lineWidth = 3
            path.stroke()
            
        default:
            break
        }
    }
    
    enum State {
        case running
        case stopped
    }
    
    /// States for a drag and drop over this task view with a task segment.
    enum DragAndDropState {
        
        /// No item is being drag and dropped into the view
        case none
        
        /// The item is accepted to be dropped on the view
        case accepted
        
        /// The item cannot be dropped on the view
        case denied
    }
}

// MARK: - Text View Delegate
extension TaskView: NSTextViewDelegate {
    
    func textDidChange(_ notification: Notification) {
        self.delegate?.taskView(self, didUpdateDescription: txtDescription.string)
    }
}

extension TaskView {
    
    /// Validates that this task view can receive a proper recognizable dropped format from
    /// a drag and drop operation described by a given dragging information object.
    /// Returns a value from the DragAndDropState enumeration describing the result of the
    /// verification, and the associated drag and drop state.
    fileprivate func verifyDrag(_ sender: NSDraggingInfo) -> (DragAndDropState, NSDragOperation) {
        let pasteBoard = sender.draggingPasteboard
        if (!pasteBoard.canReadItem(withDataConformingToTypes: [SegmentDragItemType.rawValue, NSPasteboard.PasteboardType.string.rawValue])) {
            return (.none, NSDragOperation())
        }
        
        // No delegate - return early stopping the drag
        guard let delegate = delegate else {
            return (.none, NSDragOperation())
        }
        
        // Read the segment from the pasteboard
        guard let string = pasteBoard.string(forType: SegmentDragItemType) ?? pasteBoard.string(forType: NSPasteboard.PasteboardType.string) else {
            return (.none, NSDragOperation())
        }
        
        guard let data = string.data(using: .utf8) else {
            return (.none, NSDragOperation())
        }
 
        let decoder = makeDefaultJSONDecoder()
        
        guard let segment = try? decoder.decode(TaskSegment.self, from: data) else {
            return (.none, NSDragOperation())
        }
        
        let (allow, operation) = delegate.taskView(self, allowSegmentDrop: segment, withDragInfo: sender)
        
        if(!allow) {
            return (.denied, NSDragOperation())
        }
        
        return (.accepted, operation)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let (state, operation) = verifyDrag(sender)
        dragAndDropDisplayState = state
        
        switch(dragAndDropDisplayState) {
        case .accepted:
            return operation
        default:
            return NSDragOperation()
        }
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        dragAndDropDisplayState = .none
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return verifyDrag(sender).0 == .accepted
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        dragAndDropDisplayState = .none
        
        if(verifyDrag(sender).0 != .accepted) {
            return false
        }
        
        let pasteBoard = sender.draggingPasteboard
        if (!pasteBoard.canReadItem(withDataConformingToTypes: [SegmentDragItemType.rawValue, NSPasteboard.PasteboardType.string.rawValue])) {
            return false
        }
        guard let string = pasteBoard.string(forType: SegmentDragItemType) ?? pasteBoard.string(forType: .string) else {
            return false
        }
        guard let data = string.data(using: .utf8) else {
            return false
        }
        
        let decoder = makeDefaultJSONDecoder()
        
        guard let segment = try? decoder.decode(TaskSegment.self, from: data) else {
            return false
        }
        
        return delegate?.taskView(self, didDropSegment: segment, withDragInfo: sender) ?? false
    }
}
