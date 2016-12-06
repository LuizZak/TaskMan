//
//  TaskController.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 16/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

/// Delegate for actions performed in a task controller
protocol TaskControllerDelegate: class {
    /// Called to notify a task controller had a task created
    func taskController(_ controller: TaskController, didCreateTask task: Task)
    
    /// Called to notify a task will be removed from a task controller
    func taskController(_ controller: TaskController, didRemoveTask task: Task)
    
    /// Called to notify a task has started execution
    func taskController(_ controller: TaskController, didStartTask task: Task)
    
    /// Called to notify a task has stopped executing, also providing the task segment that was created in the process.
    func taskController(_ controller: TaskController, didStopTask task: Task, newSegment: TaskSegment)
}

extension TaskControllerDelegate {
    func taskController(_ controller: TaskController, didCreateTask task: Task) { }
    func taskController(_ controller: TaskController, didRemoveTask task: Task) { }
    func taskController(_ controller: TaskController, didStartTask task: Task) { }
    func taskController(_ controller: TaskController, didStopTask task: Task, newSegment: TaskSegment) { }
}

/// Main controller for controlling tasks
class TaskController {
    
    /// Timeline of tasks executed
    var timeline: TaskTimelineManager
    
    /// Delegate for notifications of actions
    weak var delegate: TaskControllerDelegate?
    
    /// Array of currently registered tasks
    private(set) var currentTasks: [Task] = []
    
    /// Currently running task segment.
    /// Is nil, if no task is running.
    private(set) var runningSegment: TaskSegment?
    
    /// Gets the currently running task, if any.
    var runningTask: Task? {
        return runningSegment.flatMap { getTask(withId: $0.taskId) }
    }
    
    init(timeline: TaskTimelineManager) {
        self.timeline = timeline
    }
    
    init(tasks: [Task], runningSegment: TaskSegment?, timeline: TaskTimelineManager) {
        self.currentTasks = tasks
        self.timeline = timeline
        self.runningSegment = runningSegment
    }
    
    /// Creates a new task, returning the ID of the created task.
    /// A `startRunning` flag specifies whether to initiate the task as soon as it is created
    func createTask(startRunning: Bool, name: String? = nil, description: String? = nil) -> Task {
        let task = Task(id: getUniqueId(), name: name ?? "", description: description ?? "")
        
        currentTasks.append(task)
        
        if(startRunning) {
            startTask(taskId: task.id)
        }
        
        delegate?.taskController(self, didCreateTask: task)
        
        return task
    }
    
    /// Starts execution of a task with a given ID.
    /// Automatically stops any currently running tasks
    /// No task is started, if taskId is inexistent
    func startTask(taskId: Task.IDType) {
        // Stop any currently running tasks
        let last = stopCurrentTask()
        
        guard let task = getTask(withId: taskId) else {
            return
        }
        
        let range = DateRange(startDate: last?.range.endDate ?? Date(), endDate: Date())
        
        runningSegment = TaskSegment(id: timeline.getUniqueSegmentId(),
                                     taskId: task.id,
                                     range: range)
        
        delegate?.taskController(self, didStartTask: task)
    }
    
    /// Stops execution of the currently running task
    /// Returns the task segment saved, or nil, if no task is currently running
    @discardableResult
    func stopCurrentTask() -> TaskSegment? {
        guard var segment = runningSegment, let task = getTask(withId: segment.taskId) else {
            return nil
        }
        
        // Add an end date and store
        segment.range.endDate = Date()
        
        timeline.add(segment: segment)
        
        runningSegment = nil
        
        delegate?.taskController(self, didStopTask: task, newSegment: segment)
        
        return segment
    }
    
    /// Gets the total runtime for a given task, including any currently running task segments, for a given task id
    func totalTime(forTaskId id: Task.IDType) -> TimeInterval {
        var total = timeline.totalTime(forTaskId: id)
        if let runningSegment = runningSegment, runningSegment.taskId == id {
            total += runningSegment.range.timeInterval
        }
        
        return total
    }
    
    /// Removes a task with a given id from this task controller
    func removeTask(withId id: Task.IDType) {
        // Stop the current task, if it's the one to be removed
        if(runningSegment?.taskId == id) {
            stopCurrentTask()
        }
        
        // Remove all segments of the task from the timeline
        timeline.removeSegmentsForTaskId(id)
        for (i, task) in currentTasks.enumerated() {
            if(task.id == id) {
                currentTasks.remove(at: i)
                delegate?.taskController(self, didRemoveTask: task)
                break
            }
        }
    }
    
    func updateTask(withId id: Task.IDType, description: String? = nil, name: String? = nil) {
        guard var task = getTask(withId: id) else {
            return
        }
        
        if let description = description {
            task.description = description
        }
        if let name = name {
            task.name = name
        }
        
        updateTask(task)
    }
    
    /// Updates the end date of the currently running segment.
    /// Does nothing, if there are no tasks currently running
    func updateRunningSegment(withEndDate date: Date = Date()) {
        runningSegment?.range.endDate = date
    }
    
    /// Updates the start date of the currently running segment.
    /// Does nothing, if there are no tasks currently running
    func updateRunningSegment(withStartDate date: Date = Date()) {
        runningSegment?.range.startDate = date
    }
    
    /// Gets a task by ID from this task controller
    func getTask(withId id: Task.IDType) -> Task? {
        return currentTasks.first { $0.id == id }
    }
    
    /// Gets a task by name from this task controller
    func getTask(withName name: String) -> Task? {
        return currentTasks.first { $0.name == name }
    }
    
    fileprivate func updateTask(_ task: Task) {
        for (i, t) in currentTasks.enumerated() {
            if(t.id == task.id) {
                currentTasks[i] = task
            }
        }
    }
    
    /// Generates a unique task ID
    fileprivate func getUniqueId() -> Task.IDType {
        return time(nil) + (currentTasks.max(by: { $0.id < $1.id })?.id ?? 0) + 1
    }
}

/// Protocol for notification of timeline manager events
protocol TaskTimelineManagerDelegate: class {
    /// Called to notify a new task segment was added to a given manager
    func taskTimelineManager(_ manager: TaskTimelineManager, didAddSegment: TaskSegment)
    
    /// Called to notify a series of new task segments where added to a given manager
    func taskTimelineManager(_ manager: TaskTimelineManager, didAddSegments: [TaskSegment])
    
    /// Called to notify a new task segment is goint go be removed from a given manager
    func taskTimelineManager(_ manager: TaskTimelineManager, didRemoveSegment: TaskSegment)
    
    /// Called to notify a list of segments will be removed from a given manager, following a removal-by-task id
    func taskTimelineManager(_ manager: TaskTimelineManager, didRemoveSegments: [TaskSegment])
    
    /// Called to notify that a task segment had its date range updated on a given manager
    func taskTimelineManager(_ manager: TaskTimelineManager, didUpdateSegment: TaskSegment)
}

extension TaskTimelineManagerDelegate {
    func taskTimelineManager(_ manager: TaskTimelineManager, didAddSegment: TaskSegment) { }
    func taskTimelineManager(_ manager: TaskTimelineManager, didAddSegments: [TaskSegment]) { }
    func taskTimelineManager(_ manager: TaskTimelineManager, didRemoveSegment: TaskSegment) { }
    func taskTimelineManager(_ manager: TaskTimelineManager, didRemoveSegments: [TaskSegment]) { }
    func taskTimelineManager(_ manager: TaskTimelineManager, didUpdateSegment: TaskSegment) { }
}

/// A class that is used to keep track of time segments that tasks executed
class TaskTimelineManager {
    
    /// Array of task segments stored
    private(set) var segments: [TaskSegment] = []
    
    /// Notifier-delegate for this task timeline manager
    weak var delegate: TaskTimelineManagerDelegate?
    
    init(segments: [TaskSegment] = []) {
        self.segments = segments
    }
    
    /// Creates a segment for a given task ID, on a given date range on this task timeline manager
    func createSegment(forTaskId taskId: Task.IDType, dateRange: DateRange) {
        let segment = TaskSegment(id: getUniqueSegmentId(), taskId: taskId, range: dateRange)
        add(segment: segment)
    }
    
    /// Adds a given task segment to this timeline manager
    func add(segment: TaskSegment) {
        segments.append(segment)
        
        delegate?.taskTimelineManager(self, didAddSegment: segment)
    }
    
    /// Adds multiple segments to this timeline manager
    func addSegments(_ segments: [TaskSegment]) {
        self.segments.append(contentsOf: segments)
        
        delegate?.taskTimelineManager(self, didAddSegments: segments)
    }
    
    /// Sets the start/end dates of the segment with a given ID.
    /// Does nothing, if no segment with a matching ID is found
    func setSegmentRange(withId id: TaskSegment.IDType, startDate: Date, endDate: Date) {
        for (i, segment) in segments.enumerated() {
            if(segment.id == id) {
                segments[i].range = DateRange(startDate: startDate, endDate: endDate)
                self.delegate?.taskTimelineManager(self, didUpdateSegment: segments[i])
                break
            }
        }
    }
    
    /// Changes a segment's task id to be of a specified task ID.
    /// Does nothing, if the segment is unexisting, or it's task Id is already of the provided taskId
    func changeTaskForSegment(segmentId id: TaskSegment.IDType, toTaskId taskId: Task.IDType) {
        for (i, segment) in segments.enumerated() {
            if(segment.id == id && segments[i].taskId != taskId) {
                segments[i].taskId = taskId
                self.delegate?.taskTimelineManager(self, didUpdateSegment: segments[i])
                break
            }
        }
    }
    
    /// Removes a segment with a given ID from this task timeline
    func removeSegment(withId id: TaskSegment.IDType) {
        for (i, segment) in segments.enumerated() {
            if(segment.id == id) {
                segments.remove(at: i)
                self.delegate?.taskTimelineManager(self, didRemoveSegment: segment)
                break
            }
        }
    }
    
    /// Removes all segments for a given task ID
    func removeSegmentsForTaskId(_ taskId: Task.IDType) {
        // Collect segments to be removed for notification
        let segsToRemove = segments(forTaskId: taskId)
        
        // Filter all that are not associated with the requested task id
        segments = segments.filter { $0.taskId != taskId }
        
        delegate?.taskTimelineManager(self, didRemoveSegments: segsToRemove)
    }
    
    /// Removes all segments from this task timeline
    func removeAllSegments() {
        let segs = segments
        segments.removeAll()
        
        delegate?.taskTimelineManager(self, didRemoveSegments: segs)
    }
    
    /// Gets all segments for a given task ID on this task timeline manager
    func segments(forTaskId taskId: Task.IDType) -> [TaskSegment] {
        return segments.filter { $0.taskId == taskId }
    }
    
    /// Returns a task segment with a given ID
    func segment(withId id: TaskSegment.IDType) -> TaskSegment? {
        return segments.first { $0.id == id }
    }
    
    /// Gets the total time interval for a given task ID on this timeline manager
    func totalTime(forTaskId taskId: Task.IDType) -> TimeInterval {
        return segments(forTaskId: taskId).reduce(0) { $0 + $1.range.timeInterval }
    }
    
    /// Returns the earliest task segment date on this timeline manager.
    /// Returns nil, if no task segment is currently registered
    func earliestDate() -> Date? {
        return segments.earliestSegmentDate()
    }
    
    /// Returns the latest task segment date on this timeline manager.
    /// Returns nil, if no task segment is currently registered
    func latestDate() -> Date? {
        return segments.latestSegmentDate()
    }
    
    /// Generates a unique task segment ID
    fileprivate func getUniqueSegmentId() -> TaskSegment.IDType {
        return time(nil) + (segments.max(by: { $0.id < $1.id })?.id ?? 0) + 1
    }
}

extension Collection where Iterator.Element == TaskSegment {
    
    /// Returns the earliest task segment date on this segments collection.
    /// Returns nil, if this collection is empty.
    func earliestSegmentDate() -> Date? {
        return self.map { $0.range.startDate }.min(by: <)
    }
    
    /// Returns the latest task segment date on this segments collection.
    /// Returns nil, if this collection is empty.
    func latestSegmentDate() -> Date? {
        return self.map { $0.range.endDate }.max(by: <)
    }
}
