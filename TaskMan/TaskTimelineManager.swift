//
//  TaskTimelineManager.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 13/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

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
    
    /// Gets all segments within a given date range
    func segments(inRange range: DateRange) -> [TaskSegment] {
        return segments.filter { $0.range.intersects(with: range) }
    }
    
    /// Returns a task segment with a given ID
    func segment(withId id: TaskSegment.IDType) -> TaskSegment? {
        return segments.first { $0.id == id }
    }
    
    /// Gets a list of all segments that end before a given date
    func segments(endingBefore date: Date) -> [TaskSegment] {
        return segments.filter { $0.range.endDate < date }
    }
    
    /// Gets a list of all segments that start after a given date
    func segments(startingAfter date: Date) -> [TaskSegment] {
        return segments.filter { $0.range.startDate > date }
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
    func getUniqueSegmentId() -> TaskSegment.IDType {
        return time(nil) + (segments.max(by: { $0.id < $1.id })?.id ?? 0) + 1
    }
}

