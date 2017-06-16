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
    //fileprivate(set) var segments: [TaskSegment] = []
    var segments: [TaskSegment] {
        return segmentsNode.allSegments()
    }
    
    fileprivate var segmentsNode: SegmentsNode
    
    /// Notifier-delegate for this task timeline manager
    weak var delegate: TaskTimelineManagerDelegate?
    
    init(segments: [TaskSegment] = []) {
        //self.segments = segments
        self.segmentsNode = SegmentsNode(with: segments)
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
        //segments.append(segment)
        segmentsNode.insertUpdatingRanges(segment)
        
        delegate?.taskTimelineManager(self, didAddSegment: segment)
    }
    
    /// Adds multiple segments to this timeline manager
    func addSegments(_ segments: [TaskSegment]) {
        //self.segments.append(contentsOf: segments)
        segmentsNode.insertUpdatingRanges(segments)
        
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
        
        guard var segment = segmentsNode.segment(withId: id) else {
            return
        }
        
        let original = segment.range
        segment.range.startDate = startDate ?? original.startDate
        segment.range.endDate = endDate ?? original.endDate
        
        segmentsNode.removeSegment(withId: id)
        
        segmentsNode.insertUpdatingRanges(segment)
        
        // Only notify delegate if a change was detected
        if(segment.range != original) {
            self.delegate?.taskTimelineManager(self, didUpdateSegment: segment)
            return
        }
        
        /*
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
        */
    }
    
    /// Changes a segment's task id to be of a specified task ID.
    /// Does nothing, if the segment is unexisting, or it's task Id is already of the provided taskId
    func changeTaskForSegment(segmentId id: TaskSegment.IDType, toTaskId taskId: Task.IDType) {
        guard var segment = segmentsNode.segment(withId: id) else {
            return
        }
        
        segment.taskId = taskId
        segmentsNode.removeSegment(withId: id)
        segmentsNode.insert(segment)
        /*
        for (i, segment) in segments.enumerated() {
            if(segment.id == id && segments[i].taskId != taskId) {
                segments[i].taskId = taskId
                self.delegate?.taskTimelineManager(self, didUpdateSegment: segments[i])
                break
            }
        }
        */
    }
    
    /// Removes a segment with a given ID from this task timeline
    func removeSegment(withId id: TaskSegment.IDType) {
        segmentsNode.removeSegment(withId: id)
        
        /*
        for (i, segment) in segments.enumerated() {
            if(segment.id == id) {
                segments.remove(at: i)
                self.delegate?.taskTimelineManager(self, didRemoveSegment: segment)
                break
            }
        }
        */
    }
    
    /// Removes all segments for a given task ID
    func removeSegmentsForTaskId(_ taskId: Task.IDType) {
        /*
        // Collect segments to be removed for notification
        let segsToRemove = segments(forTaskId: taskId)
        
        // Filter all that are not associated with the requested task id
        segments = segments.filter { $0.taskId != taskId }
        */
        
        let segsToRemove = segmentsNode.removeSegments(forTaskId: taskId)
        
        delegate?.taskTimelineManager(self, didRemoveSegments: segsToRemove)
    }
    
    /// Removes all segments from this task timeline
    func removeAllSegments() {
        let segs = segments
        
        //segments.removeAll()
        segmentsNode = SegmentsNode(with: [])
        
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
    
    /// Gets the total time interval for a given task ID on this timeline manager,
    /// with an optional flag to indicate whether to include overlapped time ranges
    func totalTime(forTaskId taskId: Task.IDType, withOverlap: Bool = false) -> TimeInterval {
        return totalTime(forSegments: segments(forTaskId: taskId), withOverlap: withOverlap)
    }
    
    /// Gets the total time interval for all segments on this timeline manager,
    /// with an optional flag to indicate whether to include overlapped time ranges
    func totalTime(withOverlap: Bool = false) -> TimeInterval {
        return totalTime(forSegments: segments, withOverlap: withOverlap)
    }
    
    fileprivate func totalTime(forSegments segments: [TaskSegment], withOverlap: Bool = false) -> TimeInterval {
        guard let start = segments.earliestSegmentDate(), let end = segments.latestSegmentDate() else {
            return 0
        }
        
        let node = SegmentsNode(startDate: start, endDate: end)
        if(!withOverlap) {
            // Insert all nodes into the segments node above for faster querying
            // of intersections
            for segment in segments {
                node.insert(segment)
            }
            
            return node.fastMergeSegmentRanges().reduce(0) { $0 + $1.timeInterval }
        }
        
        var time: TimeInterval = 0
        for segment in segments {
            time += segment.range.timeInterval
        }
        
        return time
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
        let original = segments(forTaskId: taskId).sorted { $0.range.startDate < $1.range.startDate }
        var result: [TaskSegment] = original
        
        // Sequentially join the segments
        var index = 0
        var changed = false
        while index < result.count - 1 {
            let cur = result[index]
            let next = result[index + 1]
            
            // Combine with previous segment, then remove next segment on the
            // sequence
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
        
        // Now we remove irrelevant segments and replace the date ranges of the
        // resulting segments
        let resultIds = result.map { $0.id }
        let removed = original.filter { !resultIds.contains($0.id) }
        let removedIds = Set(removed.map { $0.id })
        
        // Update segments one by one
        for item in result {
            self.setSegmentDates(withId: item.id, startDate: item.range.startDate, endDate: item.range.endDate)
        }
        
        for id in removedIds {
            segmentsNode.removeSegment(withId: id)
        }
        //segments.remove { removedIds.contains($0.id) }
        
        delegate?.taskTimelineManager(self, didRemoveSegments: removed)
        
        return
    }
}


extension Sequence where Iterator.Element == TaskSegment {
    
    /// Returns the earliest task segment date on this segments sequence.
    /// Returns nil, if this collection is empty.
    func earliestSegmentDate() -> Date? {
        return self.min { $0.range.startDate < $1.range.startDate }?.range.startDate
    }
    
    /// Returns the latest task segment date on this segments sequence.
    /// Returns nil, if this collection is empty.
    func latestSegmentDate() -> Date? {
        return self.max { $0.range.endDate < $1.range.endDate }?.range.endDate
    }
    
    /// Returns a time interval that matches the sum of every date range of every
    /// segment on this sequence of segments
    func intervalSum() -> TimeInterval {
        return self.reduce(0) { $0 + $1.range.timeInterval }
    }
    
    /// Returns the total range that covers the start of the earliest segment to
    /// the end of the last segment.
    ///
    /// Returns nil, if this sequence is empty.
    ///
    /// - Returns: The smallest date range for this segment collection that covers
    /// all segments, or nil, if this sequence is empty.
    func totalRange() -> DateRange? {
        var range: DateRange?
        
        for segment in self {
            if let r = range {
                range = r.union(with: segment.range)
            } else {
                range = segment.range
            }
        }
        
        return range
    }
}

