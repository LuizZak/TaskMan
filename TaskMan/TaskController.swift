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
    
    /// Called to notify a task's inner properties (name, description, etc.) where updated.
    /// This delegate method is not called when the task's associated segments are updated, only
    /// the immediate properties of the task.
    func taskController(_ controller: TaskController, didUpdateTask task: Task)
    
    /// Called to notify a task has started execution
    func taskController(_ controller: TaskController, didStartTask task: Task)
    
    /// Called to notify a task has stopped executing, also providing the task segment that was created in the process.
    func taskController(_ controller: TaskController, didStopTask task: Task, newSegment: TaskSegment)
}

extension TaskControllerDelegate {
    func taskController(_ controller: TaskController, didCreateTask task: Task) { }
    func taskController(_ controller: TaskController, didRemoveTask task: Task) { }
    func taskController(_ controller: TaskController, didUpdateTask task: Task) { }
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
        
        let original = task
        
        if let description = description {
            task.description = description
        }
        if let name = name {
            task.name = name
        }
        
        // Check if the task has not changed its properties
        if(task == original) {
            return
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
                self.delegate?.taskController(self, didUpdateTask: currentTasks[i])
                break
            }
        }
    }
    
    /// Generates a unique task ID
    fileprivate func getUniqueId() -> Task.IDType {
        return time(nil) + (currentTasks.max(by: { $0.id < $1.id })?.id ?? 0) + 1
    }
}

extension Collection where Iterator.Element == TaskSegment {
    
    /// Returns the earliest task segment date on this segments collection.
    /// Returns nil, if this collection is empty.
    func earliestSegmentDate() -> Date? {
        return self.min { $0.range.startDate < $1.range.startDate }?.range.startDate
    }
    
    /// Returns the latest task segment date on this segments collection.
    /// Returns nil, if this collection is empty.
    func latestSegmentDate() -> Date? {
        return self.max { $0.range.endDate < $1.range.endDate }?.range.endDate
    }
}
