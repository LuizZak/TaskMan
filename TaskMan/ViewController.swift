//
//  ViewController.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 16/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var tasksTimelineView: TimelineView!
    @IBOutlet weak var tasksScrollView: NSScrollView!
    @IBOutlet weak var tasksContainerView: NSView!
    @IBOutlet weak var tasksHeightConstraint: NSLayoutConstraint!
    
    fileprivate var dateRange: DateRange = DateRange(startDate: Date(), endDate: Date().addingTimeInterval(8 * 60 * 60))
    
    fileprivate var secondUpdateTimer: Timer!
    
    fileprivate var taskController: TaskController!
    
    fileprivate var taskViews: [TaskView] = []
    
    override var representedObject: Any? {
        didSet {
            var tasks: [Task] = []
            var segments: [TaskSegment] = []
            var running: TaskSegment?
            var dateRange: DateRange = DateRange(startDate: Date(), endDate: Date().addingTimeInterval(8 * 60 * 60))
            
            if let document = representedObject as? TaskManDocument {
                tasks = document.taskManState.taskList.tasks
                segments = document.taskManState.taskList.taskSegments
                running = document.taskManState.runningSegment
                dateRange = document.taskManState.timeRange
            }
            
            let timeline = TaskTimelineManager(segments: segments)
            timeline.delegate = self
            
            self.taskController = TaskController(tasks: tasks, runningSegment: running, timeline: timeline)
            self.taskController.delegate = self
            
            self.dateRange = dateRange
            
            removeAllTaskViews()
            
            for task in taskController.currentTasks {
                addView(forTask: task)
            }
            
            // Move task for the currently running segment, if any, to the top
            if let running = running, let task = taskController.getTask(withId: running.taskId), let taskView = viewForTask(task: task) {
                if let i = taskViews.index(of: taskView) {
                    taskViews.remove(at: i)
                    taskViews.append(taskView)
                }
            }
            
            updateTaskViews()
            updateTimelineViews()
        }
    }
    
    var document: TaskManDocument? {
        return self.view.window?.windowController?.document as? TaskManDocument
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tasksTimelineView.dataSource = self
        tasksTimelineView.delegate = self
        tasksTimelineView.userTag = -1
        
        let timeline = TaskTimelineManager()
        timeline.delegate = self
        
        taskController = TaskController(timeline: timeline)
        taskController.delegate = self
        
        for task in taskController.currentTasks {
            addView(forTask: task)
        }
        
        secondUpdateTimer = Timer(timeInterval: 0.5, target: self, selector: #selector(ViewController.timerDidFire), userInfo: nil, repeats: true)
        
        RunLoop.current.add(secondUpdateTimer, forMode: .defaultRunLoopMode)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Update represented object
        representedObject = document
        
        if let window = self.view.window {
            if let screenSize = window.screen?.frame.size {
                window.setFrameOrigin(NSPoint(x: (screenSize.width - window.frame.size.width) / 2, y: (screenSize.height - window.frame.size.height) / 2))
            }
        }
    }
    
    func timerDidFire() {
        // Update running segment and views
        if(taskController.runningSegment != nil) {
            taskController.updateRunningSegment(withEndDate: Date())
            updateTaskViews(updateType: .RuntimeLabel)
            updateTimelineViews()
        }
    }
    
    // MARK: - Tasks View Management
    @discardableResult
    func addView(forTask task: Task) -> TaskView {
        let view = TaskView(taskId: task.id, frame: NSRect(x: 0, y: 0, width: 650, height: 146))
        
        view.viewTimeline.dataSource = self
        view.viewTimeline.delegate = self
        view.viewTimeline.userTag = task.id
        
        view.lblRuntime.stringValue = formatTimestamp(taskController.totalTime(forTaskId: task.id))
        
        view.delegate = self
        view.layer?.borderWidth = 2
        view.layer?.borderColor = NSColor.blue.cgColor
        view.layer?.masksToBounds = false
        view.txtName.stringValue = task.name
        view.txtDescription.string = task.description
        
        tasksContainerView.addSubview(view)
        
        taskViews.append(view)
        
        self.updateTaskViews()
        
        return view
    }
    
    func removeAllTaskViews() {
        for view in taskViews {
            view.removeFromSuperview()
            view.delegate = nil
        }
        
        taskViews.removeAll()
        
        updateTaskViews()
        tasksContainerView.layout()
        tasksScrollView.contentView.layout()
    }
    
    func removeViewForTask(task: Task) {
        guard let taskView = viewForTask(task: task) else {
            return
        }
        
        for (i, view) in taskViews.enumerated() {
            if(view.taskId == taskView.taskId) {
                view.removeFromSuperview()
                view.delegate = nil
                taskViews.remove(at: i)
            }
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.20
            context.allowsImplicitAnimation = true
            self.updateTaskViews()
            self.tasksContainerView.layout()
            self.tasksScrollView.contentView.layout()
        })
    }
    
    func selectViewForTask(task: Task) {
        guard let view = viewForTask(task: task) else {
            return
        }
        selectTaskView(taskView: view)
    }
    
    func selectTaskView(taskView: TaskView) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.20
            context.allowsImplicitAnimation = true
            self.tasksScrollView.contentView.scrollToVisible(taskView.frame)
        })
        self.view.window?.makeFirstResponder(taskView.txtDescription)
    }
    
    func viewForTask(task: Task) -> TaskView? {
        return taskViews.first { $0.taskId == task.id }
    }
    
    fileprivate func updateTaskViews(updateType: TaskViewUpdateType = .Full) {
        for (i, view) in taskViews.enumerated() {
            if(updateType.contains(.Position)) {
                view.frame.origin.y = CGFloat(i * 166)
                view.frame.size.width = 650
                view.frame.origin.x = tasksContainerView.frame.width / 2 - view.frame.width / 2
            }
            if(updateType.contains(.DisplayState)) {
                view.displayState = taskController.runningTask?.id == view.taskId ? .running : .stopped
            }
            if(updateType.contains(.RuntimeLabel)) {
                view.lblRuntime.stringValue = formatTimestamp(taskController.totalTime(forTaskId: view.taskId))
            }
        }
        
        if(updateType.contains(.Position)) {
            tasksHeightConstraint.constant = CGFloat(taskViews.count * 166)
            tasksContainerView.needsLayout = true
        }
    }
    
    func updateTimelineViews() {
        for view in taskViews {
            view.viewTimeline.needsDisplay = true
        }
        tasksTimelineView.needsDisplay = true
    }
    
    /// Return the default palete colors
    static func defaultColors() -> [NSColor] {
        
        return [
            NSColor(red: 39.0/255.0,    green: 78.0/255.0,  blue: 192.0/255.0,  alpha: 1),
            NSColor(red: 209.0/255.0,   green: 36.0/255.0,  blue: 17.0/255.0,   alpha: 1),
            NSColor(red: 253.0/255.0,   green: 134.0/255.0, blue: 9.0/255.0,    alpha: 1),
            NSColor(red: 23.0/255.0,    green: 136.0/255.0, blue: 19.0/255.0,   alpha: 1),
            NSColor(red: 133.0/255.0,   green: 0.0/255.0,   blue: 135.0/255.0,  alpha: 1),
            NSColor(red: 17.0/255.0,    green: 135.0/255.0, blue: 185.0/255.0,  alpha: 1),
            NSColor(red: 210.0/255.0,   green: 43.0/255.0,  blue: 100.0/255.0,  alpha: 1),
            NSColor(red: 86.0/255.0,    green: 157.0/255.0, blue: 5.0/255.0,    alpha: 1),
            NSColor(red: 167.0/255.0,   green: 28.0/255.0,  blue: 35.0/255.0,   alpha: 1),
            NSColor(red: 39.0/255.0,    green: 79.0/255.0,  blue: 139.0/255.0,  alpha: 1),
            NSColor(red: 134.0/255.0,   green: 45.0/255.0,  blue: 134.0/255.0,  alpha: 1),
            NSColor(red: 33.0/255.0,    green: 155.0/255.0, blue: 135.0/255.0,  alpha: 1),
            NSColor(red: 154.0/255.0,   green: 157.0/255.0, blue: 16.0/255.0,   alpha: 1),
            NSColor(red: 82.0/255.0,    green: 22.0/255.0,  blue: 193.0/255.0,  alpha: 1)
        ]
    }
    
    // MARK: - Actions
    
    @IBAction func didTapAddTaskButton(_ sender: NSButton) {
        addNewTask(running: false)
    }
    
    @IBAction func didTapAddAndStartTaskButton(_ sender: NSButton) {
        addNewTask(running: true)
    }
    
    private func addNewTask(running: Bool) {
        // Figure out a unique name for the task
        var num = 1
        while(taskController.getTask(withName: "New Task #\(num)") != nil) {
            num += 1
        }
        
        let task = taskController.createTask(startRunning: running, name: "New Task #\(num)", description: "")
        
        addView(forTask: task)
        
        // Layout to update constraints before selecting the view
        tasksScrollView.contentView.layout()
        
        selectViewForTask(task: task)
    }
    
    @IBAction func didTapEditStartEndTime(_ sender: NSButton) {
        guard let controller = storyboard?.instantiateController(withIdentifier: "editDateRange") as? EditDateRangeViewController else {
            return
        }
        
        controller.setDateRange(dateRange: dateRange)
        
        controller.didTapOkCallback = { (controller) -> Void in
            self.dateRange.startDate = controller.startDate
            self.dateRange.endDate = controller.endDate
            self.markChangesPending()
            
            self.updateTimelineViews()
            
            controller.dismiss(self)
        }
        
        presentViewControllerAsModalWindow(controller)
    }
    
    // MARK: Segment menu buttons
    func didTapRemoveSegment(_ sender: NSMenuItem) {
        guard let segment = sender.representedObject as? TaskSegment else {
            return
        }
        
        taskController.timeline.removeSegment(withId: segment.id)
    }
    
    // MARK: Segment List menu buttons
    func didTapAddSegmentOnTaskView(_ sender: NSMenuItem) {
        guard let taskView = sender.representedObject as? TaskView else {
            return
        }
        guard let controller = storyboard?.instantiateController(withIdentifier: "editDateRange") as? EditDateRangeViewController else {
            return
        }
        
        controller.setDateRange(dateRange: DateRange(startDate: Date(), endDate: Date().addingTimeInterval(60 * 60)))
        
        controller.didTapOkCallback = { (controller) -> Void in
            let range = DateRange(startDate: controller.startDate, endDate: controller.endDate)
            self.taskController.timeline.createSegment(forTaskId: taskView.taskId, dateRange: range)
            
            self.updateTimelineViews()
            self.updateTaskViews(updateType: .RuntimeLabel)
            
            controller.dismiss(self)
        }
        
        presentViewControllerAsModalWindow(controller)
    }
    
    func didTapEditSegmentDates(_ sender: NSMenuItem) {
        guard let segment = sender.representedObject as? TaskSegment else {
            return
        }
        guard let controller = storyboard?.instantiateController(withIdentifier: "editDateRange") as? EditDateRangeViewController else {
            return
        }
        
        controller.setDateRange(dateRange: segment.range)
        
        controller.didTapOkCallback = { (controller) -> Void in
            self.taskController.timeline.setSegmentRange(withId: segment.id, startDate: controller.startDate, endDate: controller.endDate)
            
            controller.dismiss(self)
        }
        
        presentViewControllerAsModalWindow(controller)
    }
    
    func didTapChangeSegmentTask(_ sender: NSMenuItem) {
        
        guard let segment = sender.representedObject as? TaskSegment, let sourceTask = taskController.getTask(withId: segment.taskId) else {
            return
        }
        guard let controller = ChangeSegmentTaskViewController(nibName: "ChangeSegmentTaskViewController", bundle: nil) else {
            return
        }
        
        controller.taskController = taskController
        controller.segment = segment
        
        controller.callback = { [weak self] (controller) in
            guard let sSelf = self, let task = controller.selectedTask else {
                return
            }
            
            // No change detected
            if(task.id == sourceTask.id) {
                controller.dismiss(sSelf)
                return
            }
            
            if(sSelf.confirmMoveSegment(segment, fromTask: sourceTask, toTask: task)) {
                controller.dismiss(sSelf)
            }
        }
        
        self.presentViewControllerAsModalWindow(controller)
    }
    
    func didTapEditRunnignSegmentStartDate(_ sender: NSMenuItem) {
        guard let segment = taskController.runningSegment else {
            return
        }
        guard let controller = storyboard?.instantiateController(withIdentifier: "editDate") as? EditDateViewController else {
            return
        }
        
        controller.date = segment.range.startDate
        
        controller.didTapOkCallback = { (controller) -> Void in
            if(controller.date > Date()) {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = "Please specify a date that is in the past for the running segment."
                alert.runModal()
                
                return
            }
            
            self.taskController.updateRunningSegment(withStartDate: controller.date)
            self.markChangesPending()
            
            self.updateTimelineViews()
            self.updateTaskViews(updateType: .RuntimeLabel)
            
            controller.dismiss(self)
        }
        
        presentViewControllerAsModalWindow(controller)
    }
    
    // MARK: - Selection Menu Creation
    func createSegmentMenu(forSegment segment: TaskSegment) -> NSMenu {
        let isRunning = taskController.runningSegment?.id == segment.id
        
        // Add editing start/end dates
        if(!isRunning) {
            // Delete
            let delete = NSMenuItem(title: "Delete Segment", action:#selector(ViewController.didTapRemoveSegment(_:)), keyEquivalent: "")
            delete.image = NSImage(named: "NSStopProgressFreestandingTemplate")
            delete.representedObject = segment
            
            // Edit dates
            let editDate = NSMenuItem(title: "Edit start/end", action: #selector(ViewController.didTapEditSegmentDates(_:)), keyEquivalent: "")
            editDate.image = NSImage(named: "NSActionTemplate")
            editDate.representedObject = segment
            editDate.target = self
            
            // Change task
            let changeTask = NSMenuItem(title: "Change segment's task", action: #selector(ViewController.didTapChangeSegmentTask(_:)), keyEquivalent: "")
            changeTask.image = NSImage(named: "NSShareTemplate")
            changeTask.representedObject = segment
            changeTask.target = self
            
            let sub = NSMenu()
            sub.addItem(delete)
            sub.addItem(editDate)
            sub.addItem(changeTask)
            
            return sub
        } else {
            // Add editing start date for running segment
            let editDate = NSMenuItem(title: "Edit start", action: #selector(ViewController.didTapEditRunnignSegmentStartDate(_:)), keyEquivalent: "")
            editDate.image = NSImage(named: "NSActionTemplate")
            editDate.target = self
            
            let sub = NSMenu()
            sub.addItem(editDate)
            
            return sub
        }
    }
    
    override func commitEditing() -> Bool {
        return super.commitEditing()
    }
    
    func markChangesPending() {
        document?.taskManState.runningSegment = taskController.runningSegment
        document?.taskManState.taskList = TaskList(tasks: taskController.currentTasks, taskSegments: taskController.timeline.segments)
        document?.taskManState.timeRange = dateRange
        
        document?.updateChangeCount(.changeDone)
    }
    
    // MARK: - TaskViewUpdateType
    fileprivate struct TaskViewUpdateType: OptionSet {
        let rawValue: Int
        
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        static let Position = TaskViewUpdateType(rawValue: 1)
        static let RuntimeLabel = TaskViewUpdateType(rawValue: 1 << 1)
        static let DisplayState = TaskViewUpdateType(rawValue: 1 << 2)
        static let Full = TaskViewUpdateType(rawValue: 0xFFFF)
    }
}

// MARK: - Common Interface Methods
extension ViewController {
    
    /// Shows an alert interface to confirm removal of a task, and removes it 
    /// if the user has selected 'Yes'.
    /// Returns whether the user has tapped the YES button.
    func confirmRemoveTask(_ task: Task) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to remove the task '\(task.name)'?"
        
        alert.addButton(withTitle: "Yes").keyEquivalent = "\r" // Enter
        alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}" // Esc
        
        if(alert.runModal() == NSAlertSecondButtonReturn) {
            return false
        }
        
        // Perform the segment transfer
        taskController.removeTask(withId: task.id)
        removeViewForTask(task: task)
        
        return true
    }
    
    /// Shows an alert interface to confirm creation of a segment on a tasks, and creates it
    /// if the user has selected 'Yes'.
    /// Returns whether the user has tapped the YES button to move the task segment.
    func confirmAddSegment(_ segment: TaskSegment, toTask targetTask: Task) -> Bool {
        let startDateString = tasksTimelineView.dateTimeFormatter.string(from: segment.range.startDate)
        let endDateString = tasksTimelineView.dateTimeFormatter.string(from: segment.range.endDate)
        
        let alert = NSAlert()
        alert.messageText = "Would you like to add the segment from \(startDateString) to \(endDateString) to task \(targetTask.name)?"
        
        alert.addButton(withTitle: "Yes").keyEquivalent = "\r" // Enter
        alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}" // Esc
        
        if(alert.runModal() == NSAlertSecondButtonReturn) {
            return false
        }
        
        // Perform the segment transfer
        taskController.timeline.createSegment(forTaskId: targetTask.id, dateRange: segment.range)
        
        return true
    }
    
    /// Shows an alert interface to confirm moving a segment between two tasks, and move it
    /// if the user has selected 'Yes'.
    /// Returns whether the user has tapped the YES button to move the task segment.
    func confirmMoveSegment(_ segment: TaskSegment, fromTask sourceTask: Task, toTask targetTask: Task) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Would you like to send the segment from task \(sourceTask.name) to task \(targetTask.name)?"
        
        alert.addButton(withTitle: "Yes").keyEquivalent = "\r" // Enter
        alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}" // Esc
        
        if(alert.runModal() == NSAlertSecondButtonReturn) {
            return false
        }
        
        // Perform the segment transfer
        taskController.timeline.setSegmentRange(withId: segment.id, startDate: segment.range.startDate, endDate: segment.range.endDate)
        taskController.timeline.changeTaskForSegment(segmentId: segment.id, toTaskId: targetTask.id)
        
        return true
    }
}

// MARK: - Task Timeline Delegate
extension ViewController: TaskTimelineManagerDelegate {
    func taskTimelineManager(_ manager: TaskTimelineManager, didAddSegment: TaskSegment) {
        markChangesPending()
        
        updateTimelineViews()
    }
    
    func taskTimelineManager(_ manager: TaskTimelineManager, didRemoveSegment: TaskSegment) {
        markChangesPending()
        
        updateTimelineViews()
    }
    
    func taskTimelineManager(_ manager: TaskTimelineManager, didAddSegments: [TaskSegment]) {
        markChangesPending()
        
        updateTimelineViews()
    }
    
    func taskTimelineManager(_ manager: TaskTimelineManager, didRemoveSegments: [TaskSegment]) {
        markChangesPending()
        
        updateTimelineViews()
    }
    
    func taskTimelineManager(_ manager: TaskTimelineManager, didUpdateSegment: TaskSegment) {
        markChangesPending()
        
        updateTimelineViews()
        updateTaskViews(updateType: .RuntimeLabel)
    }
}

// MARK: - Task Timeline Controller
extension ViewController: TaskControllerDelegate {
    
    func taskController(_ controller: TaskController, didCreateTask task: Task) {
        markChangesPending()
    }
    
    func taskController(_ controller: TaskController, didRemoveTask task: Task) {
        markChangesPending()
    }
    
    func taskController(_ controller: TaskController, didUpdateTask task: Task) {
        markChangesPending()
    }
    
    func taskController(_ controller: TaskController, didStartTask task: Task) {
        markChangesPending()
        
        updateTaskViews()
        updateTimelineViews()
    }
    
    func taskController(_ controller: TaskController, didStopTask task: Task, newSegment: TaskSegment) {
        markChangesPending()
        
        updateTaskViews()
        updateTimelineViews()
    }
}

// MARK: - Task View Delegate
extension ViewController: TaskViewDelegate {
    
    func taskView(_ taskView: TaskView, didUpdateName name: String) {
        taskController.updateTask(withId: taskView.taskId, name: name)
    }
    
    func taskView(_ taskView: TaskView, didUpdateDescription description: String) {
        taskController.updateTask(withId: taskView.taskId, description: description)
    }
    
    func didTapRemoveButtonOnTaskView(_ taskView: TaskView) {
        guard let task = taskController.getTask(withId: taskView.taskId) else {
            return
        }

        _=confirmRemoveTask(task)
    }
    
    func didTapStartStopButtonOnTaskView(_ taskView: TaskView) {
        // Check if task is running
        if(taskController.runningTask?.id == taskView.taskId) {
            taskController.stopCurrentTask()
        } else {
            taskController.startTask(taskId: taskView.taskId)
            
            // Re-order views, bringing the selected view to the top
            if let i = taskViews.index(of: taskView) {
                taskViews.remove(at: i)
                taskViews.append(taskView)
            }
            
            updateTaskViews()
            
            // Select task view
            selectTaskView(taskView: taskView)
        }
    }
    
    func didTapSegmentListButtonOnTaskView(_ taskView: TaskView) {
        var segments = taskController.timeline.segments(forTaskId: taskView.taskId)
        
        if let runningSegment = taskController.runningSegment, runningSegment.taskId == taskView.taskId {
            segments.insert(runningSegment, at: 0)
        }
        
        let listMenuView = NSMenu(title: "Segments List")
        
        // Add 'Add Segment' button
        let addSegment = NSMenuItem(title: "Add Segment", action: #selector(ViewController.didTapAddSegmentOnTaskView(_:)), keyEquivalent: "")
        addSegment.target = self
        addSegment.representedObject = taskView
        
        listMenuView.addItem(addSegment)
        
        for (i, segment) in segments.enumerated() {
            let formatter = taskView.viewTimeline.dateTimeFormatter
            
            let start = formatter.string(from: segment.range.startDate)
            let end = formatter.string(from: segment.range.endDate)
            
            var title = "Segment \(i + 1) \(start) to \(end)"
            let isRunning = taskController.runningSegment?.id == segment.id
            // Add label to segment to indicate it's currently running
            if(isRunning) {
                title += " - running"
            }
            
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.representedObject = segment
            
            item.submenu = createSegmentMenu(forSegment: segment)
            
            listMenuView.addItem(item)
        }
        
        listMenuView.popUp(positioning: nil, at: NSPoint(x: taskView.btnSegmentList.frame.minX, y: taskView.btnSegmentList.frame.minY), in: taskView)
    }
    
    func taskView(_ taskView: TaskView, allowSegmentDrop segment: TaskSegment, withDragInfo dragInfo: NSDraggingInfo) -> (Bool, NSDragOperation) {
        // Segment comes from an external text source - allow copying
        if(!(dragInfo.draggingSource() is TimelineView)) {
            return (true, .copy)
        }
        
        // Unrecognized source task ID
        if(taskController.getTask(withId: segment.taskId) == nil) {
            return (false, NSDragOperation())
        }
        
        // Allow exchange only between different tasks
        return (taskView.taskId != segment.taskId, .move)
    }
    
    func taskView(_ taskView: TaskView, didDropSegment segment: TaskSegment, withDragInfo dragInfo: NSDraggingInfo) -> Bool {
        // Fetch target task
        guard let targetTask = taskController.getTask(withId: taskView.taskId) else {
            return false
        }
        
        // Segment comes from an external text source - copy segment data
        if(!(dragInfo.draggingSource() is TimelineView)) {
            return confirmAddSegment(segment, toTask: targetTask)
        }
        
        // Segment comres from a timeline view - move segment data
        guard let sourceTask = taskController.getTask(withId: segment.taskId) else {
            return false
        }
        
        return confirmMoveSegment(segment, fromTask: sourceTask, toTask: targetTask)
    }
}

// MARK: - Timeline View Data Source
extension ViewController: TimelineViewDataSource {
    func segmentsForTimelineView(_ timelineView: TimelineView) -> [TaskSegment] {
        var segments = taskController.timeline.segments
        
        // Add running task segment, with the current date as the end date of the segment
        if var seg = taskController.runningSegment {
            seg.range.endDate = Date()
            
            segments.append(seg)
        }
        
        return segments
    }
    
    func timelineView(_ timelineView: TimelineView, willStartDraggingSegment segment: TaskSegment) -> Bool {
        // Only allow dragging segments that are owned by a timeline view, or coming from the general timeline view
        if(timelineView.userTag == -1) {
            return true
        }
        
        return segment.taskId == timelineView.userTag
    }
}

// MARK: - Timeline View Delegate
extension ViewController: TimelineViewDelegate {
    
    func backgroundColorForTimelineView(_ timelineView: TimelineView) -> NSColor {
        return NSColor.white
    }
    
    func timelineView(_ timelineView: TimelineView, colorForSegment segment: TaskSegment) -> NSColor {
        let index = taskController.currentTasks.index { $0.id == segment.taskId } ?? 0
        
        let colors = ViewController.defaultColors()
        
        if(timelineView.userTag != -1) {
            if(segment.taskId != timelineView.userTag) {
                return colors[index % colors.count].withAlphaComponent(0.075)
            }
        }
        
        return colors[index % colors.count]
    }
    
    func timelineView(_ timelineView: TimelineView, taskForSegment segment: TaskSegment) -> Task {
        return taskController.getTask(withId: segment.taskId)!
    }
    
    func timelineView(_ timelineView: TimelineView, labelForSegment segment: TaskSegment) -> String {
        let task = taskController.getTask(withId: segment.taskId)!
        
        var segments = taskController.timeline.segments(forTaskId: task.id)
        // Add running segment
        if let running = taskController.runningSegment, running.taskId == task.id {
            segments.append(running)
        }
        if let earliest = segments.earliestSegmentDate(), let latest = segments.latestSegmentDate() {
            let start = timelineView.dateTimeFormatter.string(from: earliest)
            let end = timelineView.dateTimeFormatter.string(from: latest)
            
            let segStart = timelineView.dateTimeFormatter.string(from: segment.range.startDate)
            let segEnd = timelineView.dateTimeFormatter.string(from: segment.range.endDate)
            
            return "\(task.name) - \(start) to \(end)\nSegment date: \(segStart) to \(segEnd)\nSegment time: \(formatTimestamp(segment.range.timeInterval))"
        }
        
        return task.name
    }
    
    func timelineView(_ timelineView: TimelineView, didTapSegment segment: TaskSegment, with event: NSEvent) {
        if(event.type == .rightMouseUp) {
            // Do nothing if this is the currently running segment
            if(segment.id == taskController.runningSegment?.id) {
                return
            }
            
            let windowPoint = event.locationInWindow
            let point = timelineView.convert(windowPoint, from: nil)
            
            let segmentMenu = createSegmentMenu(forSegment: segment)
            
            segmentMenu.popUp(positioning: nil, at: point, in: timelineView)
            
            return
        }
        
        guard timelineView.userTag == -1, let task = taskController.getTask(withId: segment.taskId) else {
            return
        }
        
        selectViewForTask(task: task)
    }
    
    func minimumStartDateForTimelineView(_ timelineView: TimelineView) -> Date? {
        return dateRange.startDate
    }
    
    func minimumEndDateForTimelineView(_ timelineView: TimelineView) -> Date? {
        return dateRange.endDate
    }
}
