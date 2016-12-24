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
    fileprivate(set) var segments: [TaskSegment] = []
    
    /// Notifier-delegate for this task timeline manager
    weak var delegate: TaskTimelineManagerDelegate?
    
    init(segments: [TaskSegment] = []) {
        self.segments = segments
    }
    
    /// Creates a segment for a given task ID, on a given date range on this task timeline manager
    @discardableResult
    func createSegment(forTaskId taskId: Task.IDType, dateRange: DateRange) -> TaskSegment {
        let segment = TaskSegment(id: getUniqueSegmentId(), taskId: taskId, range: dateRange)
        add(segment: segment)
        return segment
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
    /// Can pass nil, to not update the field.
    /// Does nothing, if no segment with a matching ID is found, or if the start/end dates did not update.
    func setSegmentDates(withId id: TaskSegment.IDType, startDate: Date? = nil, endDate: Date? = nil) {
        // If no fields are to be updated, quit early
        if startDate == nil && endDate == nil {
            return
        }
        
        for (i, segment) in segments.enumerated() {
            if(segment.id == id) {
                let original = segments[i].range
                segments[i].range.startDate = startDate ?? original.startDate
                segments[i].range.endDate = endDate ?? original.endDate
                
                // Only notify delegate if a change was detected
                if(segments[i].range != original) {
                    self.delegate?.taskTimelineManager(self, didUpdateSegment: segments[i])
                    return
                }
                return
            }
        }
        
        return
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
    
    /// Gets the total time interval for a given task ID on this timeline manager, with an optional flag
    /// to indicate whether to include overlapped time ranges
    func totalTime(forTaskId taskId: Task.IDType, withOverlap: Bool = false) -> TimeInterval {
        return totalTime(forSegments: segments(forTaskId: taskId), withOverlap: withOverlap)
    }
    
    /// Gets the total time interval for all segments on this timeline manager, with an optional flag to
    /// indicate whether to include overlapped time ranges
    func totalTime(withOverlap: Bool = false) -> TimeInterval {
        return totalTime(forSegments: segments, withOverlap: withOverlap)
    }
    
    fileprivate func totalTime(forSegments segments: [TaskSegment], withOverlap: Bool = false) -> TimeInterval {
        let segs = segments.sorted { $0.range.startDate < $1.range.startDate }
        
        // Sum total and overlap time
        var totalOverlap: TimeInterval = 0
        var totalTime: TimeInterval = 0
        for i in 0..<segs.count {
            let seg1 = segs[i]
            totalTime += seg1.range.timeInterval
            
            if(!withOverlap) {
                // Search for overlaps and increase the overlapt time
                for j in (i+1)..<segs.count {
                    let seg2 = segs[j]
                    
                    if let overlap = seg1.range.intersection(with: seg2.range) {
                        totalOverlap += overlap.timeInterval
                    } else {
                        // No overlap - we break, since the segments are sorted and that means no
                        // further overlapping segments will be found starting from this one
                        break
                    }
                }
            }
        }
        
        return totalTime - totalOverlap
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

// MARK: - Compound Operations
extension TaskTimelineManager {
    
    /// Joins all segments of a task ID that are overlapped on top of one another.
    func joinConnectedSegments(forTaskId taskId: Task.IDType) {
        // Fetch all segments
        let original = self.segments(forTaskId: taskId).sorted { $0.range.startDate < $1.range.startDate }
        var result: [TaskSegment] = original
        
        // Sequentially join the segments
        var index = 0
        var changed = false
        while index < result.count - 1 {
            let cur = result[index]
            let next = result[index + 1]
            
            // Combine with previous segment, then remove next segment on the sequence
            if(cur.range.intersects(with: next.range)) {
                result[index].range = cur.range.union(with: next.range)
                result.remove(at: index + 1)
                changed = true
            } else {
                index += 1
            }
        }
        
        // No change detected
        if(!changed) {
            return
        }
        
        // Now we remove irrelevant segments and replace the date ranges of the resulting segments
        let resultIds = result.map { $0.id }
        let removed = original.filter { !resultIds.contains($0.id) }
        let removedIds = Set(removed.map { $0.id })
        
        // Update segments one by one
        for item in result {
            self.setSegmentDates(withId: item.id, startDate: item.range.startDate, endDate: item.range.endDate)
        }
        
        segments.remove { removedIds.contains($0.id) }
        
        delegate?.taskTimelineManager(self, didRemoveSegments: removed)
        
        return
    }
}
