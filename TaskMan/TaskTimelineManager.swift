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
            
            return node.fastMergeSegmentRanges().reduce(0, { $0 + $1.timeInterval })
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
        
        segments.remove { removedIds.contains($0.id) }
        
        delegate?.taskTimelineManager(self, didRemoveSegments: removed)
        
        return
    }
}

/// Protocol for types that provide task segment querying in the form of various
/// helper methods.
protocol TaskSegmentsNodeGraph {
    
    /// Gets the range of this segments node graph
    var range: DateRange { get }
    
    /// Gets all task segments contained within this task segments node graph
    var segments: [TaskSegment] { get }
    
    /// Gets all subnodes of this task segments node graph
    func allSubNodes() -> [TaskSegmentsNodeGraph]
    
    /// Gets all task segments contained within this node graph, and all
    /// child graphs.
    func allSegments() -> [TaskSegment]
    
    /// Returns the first task segment found that contains the given date.
    ///
    /// - Parameters:
    ///   - date: Date to query.
    ///   - reverseSearch: Whether to return the last segment that is found under
    /// the point, so the search returns the segment that was added last.
    /// - Returns: First (or last, see `reverseSearch`) (but not necessarily
    /// earliest) task segment that contains the given date, or `nil`, if none
    /// are found.
    func segment(on date: Date, reverseSearch: Bool) -> TaskSegment?
    
    /// Returns the number of segments that intersect a given date range.
    ///
    /// - Parameter range: Range to query for the segments.
    /// - Returns: Count of segments intersecting `range`.
    func countOfSegments(intersecting range: DateRange) -> Int
    
    /// Returns all segments contained within a given date range.
    ///
    /// - Parameter range: Range to query for the segments.
    /// - Returns: All segments contained within the given range on this segments
    /// node.
    func allSegments(intersecting range: DateRange) -> [TaskSegment]
    
    /// Recursively queries this task segments node and runs a given block
    /// for every task segment that is overlapping over the given date range.
    ///
    /// The order of the segments is not guaranteed to be ordered.
    ///
    /// - Parameters:
    ///   - range: Range to test against.
    ///   - closure: Closure to execute for every matching task segment found.
    /// - Throws: Rethrows errors from `closure`.
    func querySegments(range: DateRange, with closure: (TaskSegment) throws -> Void) rethrows
    
    /// Iterates all segments of this segments node recursively, depth-first,
    /// calling a given closure for every task segment found.
    ///
    /// The traversal stops when the closure returns `false`.
    ///
    /// - Parameter closure: The closure to use when traversing the task segments.
    /// - Returns: `true` if method returned after complete traversal, or `false`
    /// if `closure` returns false.
    /// - Throws: Rethrows any error from `closure`.
    func iterateAllSegments(with closure: (TaskSegment) throws -> Bool) rethrows -> Bool
}

/// Tree-style node structure used to split timeline segments into grid-like
/// regions that get recursively smaller.
///
/// Used by date intersection methods used above to improve querying speed.
final class SegmentsNode: TaskSegmentsNodeGraph {
    private let maxDepth = 6
    private let maxCountBeforeSplit = 10
    
    private(set) weak var parentNode: SegmentsNode?
    
    private(set) var range: DateRange
    private(set) var subNodes: ContiguousArray<SegmentsNode> = []
    private(set) var segments: [TaskSegment] = []
    
    /// Depth of this segment node. 0 means root node
    private(set) var depth: Int = 0
    
    /// Count of segments contained within this segments node, and all sub nodes
    /// combined.
    private(set) var segmentsCount: Int = 0
    
    init(startDate: Date, endDate: Date) {
        range = startDate...endDate
        
        segments.reserveCapacity(maxCountBeforeSplit)
    }
    
    init(range: DateRange) {
        self.range = range
    }
    
    init(with segments: [TaskSegment]) {
        let start = segments.earliestSegmentDate() ?? Date()
        let end = segments.latestSegmentDate() ?? Date()
        
        range = start...end
        
        for segment in segments {
            insert(segment)
        }
    }
    
    init(with segments: [TaskSegment], range: DateRange) {
        self.range = range
        
        for segment in segments {
            insert(segment)
        }
    }
    
    @discardableResult
    func insert(_ segment: TaskSegment) -> Bool {
        if(!range.intersects(with: segment.range)) {
            return false
        }
        
        // All paths bellow end up adding a segment
        segmentsCount += 1
        
        if(segments.count < maxCountBeforeSplit || depth > maxDepth) {
            segments.append(segment)
            return true
        }
        
        subdivide()
        for node in subNodes {
            if(node.range.contains(range: segment.range)) {
                node.insert(segment)
                return true
            }
        }
        
        segments.append(segment)
        
        return true
    }
    
    /// Searches for a segment within this segments node and removes it.
    ///
    /// - Parameter id: The ID of the segment to remove.
    /// - Returns: Whether the segment was found and removed.
    func removeSegment(withId id: TaskSegment.IDType) -> Bool {
        if let index = segments.index(where: { $0.id == id }) {
            segments.remove(at: index)
            segmentsCount -= 1
            return true
        }
        
        for node in subNodes {
            if(node.removeSegment(withId: id)) {
                segmentsCount -= 1
                squashEmptySubdivisions()
                return true
            }
        }
        
        return false
    }
    
    /// Searches for a segment within this segments node, limited to a specified
    /// time range, and removes it.
    ///
    /// - Parameters:
    ///   - id: The ID of the segment to remove.
    ///   - range: Range to limit searching within.
    /// - Returns: Whether the segment was found and removed.
    func removeSegment(withId id: TaskSegment.IDType, within range: DateRange) -> Bool {
        if let index = segments.index(where: { $0.id == id }) {
            segments.remove(at: index)
            segmentsCount -= 1
            return true
        }
        
        for node in subNodes {
            if (node.range.intersects(with: range) && node.removeSegment(withId: id)) {
                segmentsCount -= 1
                squashEmptySubdivisions()
                return true
            }
        }
        
        return false
    }
    
    private func subdivide() {
        // Already split
        if(subNodes.count > 0) {
            return
        }
        
        // Split by 4
        let (left, right) = range.splitAtMiddle()
        
        let (leftLeft, leftRight) = left.splitAtMiddle()
        let (rightLeft, rightRight) = right.splitAtMiddle()
        
        subNodes = ContiguousArray([leftLeft, leftRight, rightLeft, rightRight].map(SegmentsNode.init(range:)))
        for node in subNodes {
            node.parentNode = self
            node.depth = depth + 1
        }
    }
    
    private func squashEmptySubdivisions() {
        // Already squashed
        if(subNodes.count == 0) {
            return
        }
        
        // Verify if any of the sub-nodes is populated still
        for node in subNodes {
            if(node.segmentsCount > 0) {
                return
            }
        }
        
        subNodes = []
    }
    
    func allSubNodes() -> [TaskSegmentsNodeGraph] {
        return Array(subNodes)
    }
    
    /// Fetches all segments contained within this, and all descendant nodes of
    /// this Segments Node.
    func allSegments() -> [TaskSegment] {
        var segments: [TaskSegment] = []
        segments.reserveCapacity(segmentsCount)
        
        _appendSegments(to: &segments)
        
        return segments
    }
    
    private func _appendSegments(to array: inout [TaskSegment]) {
        array.append(contentsOf: segments)
        
        for node in subNodes {
            node._appendSegments(to: &array)
        }
    }
}

// MARK: - Segments Node Iteration
extension SegmentsNode {
    /// Iterates this, and all children segments nodes that overlap the given date,
    /// calling a closure along the way.
    ///
    /// Closure is not called at all if `date` is outside the range of this segments
    /// node.
    ///
    /// - Parameters:
    ///   - date: Date to use on overlap.
    ///   - closure: The closure to call with each segments node that overlaps
    /// the given point.
    /// - Throws: Rethrows any error thrown by `closure`.
    func iterateNodes(containing date: Date, with closure: (SegmentsNode) throws -> Void) rethrows {
        if !range.contains(date: date) {
            return
        }
        
        try closure(self)
        
        for node in subNodes {
            if node.range.contains(date: date) {
                try node.iterateNodes(containing: date, with: closure)
            }
        }
    }
}

// MARK: - Segment Iteration/querying
extension SegmentsNode {
    
    /// Returns the first task segment found that contains the given date.
    ///
    /// - Parameters:
    ///   - date: Date to query.
    ///   - reverseSearch: Whether to return the last segment that is found under
    /// the point, so the search returns the segment that was added last.
    /// - Returns: First (or last, see `reverseSearch`) (but not necessarily
    /// earliest) task segment that contains the given date, or `nil`, if none
    /// are found.
    func segment(on date: Date, reverseSearch: Bool = false) -> TaskSegment? {
        for segment in (reverseSearch ? segments.reversed() : segments) {
            if(segment.range.contains(date: date)) {
                return segment
            }
        }
        
        if reverseSearch {
            for node in subNodes.reversed() {
                if(node.range.contains(date: date)) {
                    if let segment = node.segment(on: date) {
                        return segment
                    }
                }
            }
        } else {
            for node in subNodes {
                if(node.range.contains(date: date)) {
                    if let segment = node.segment(on: date) {
                        return segment
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Returns the number of segments that intersect a given date range.
    ///
    /// - Parameter range: Range to query for the segments.
    /// - Returns: Count of segments intersecting `range`.
    func countOfSegments(intersecting range: DateRange) -> Int {
        var count = 0
        
        for segment in segments {
            if(segment.range.intersects(with: range)) {
                count += 1
            }
        }
        
        for node in subNodes {
            if(node.range.intersects(with: range)) {
                count += node.countOfSegments(intersecting: range)
            }
        }
        
        return count
    }
    
    /// Returns all segments contained within a given date range.
    ///
    /// - Parameter range: Range to query for the segments.
    /// - Returns: All segments contained within the given range on this segments
    /// node.
    func allSegments(intersecting range: DateRange) -> [TaskSegment] {
        var array: [TaskSegment] = []
        
        _appendAllSegments(intersecting: range, to: &array)
        
        return array
    }
    
    private func _appendAllSegments(intersecting range: DateRange, to array: inout [TaskSegment]) {
        for segment in segments {
            if(segment.range.intersects(with: range)) {
                array.append(segment)
            }
        }
        
        for node in subNodes {
            if(node.range.intersects(with: range)) {
                node._appendAllSegments(intersecting: range, to: &array)
            }
        }
    }
    
    /// Recursively queries this task segments node and runs a given block
    /// for every task segment that is contained over the given date, then
    /// returning the first segment that returns `true` for the closure.
    ///
    /// The order of the segments is not guaranteed to be ordered.
    ///
    /// - Parameters:
    ///   - date: Date to test against.
    ///   - closure: Closure to execute for every matching task segment found.
    /// - Throws: Rethrows errors from `closure`.
    func firstSegment(on date: Date, where closure: (TaskSegment) throws -> Bool) rethrows -> TaskSegment? {
        for segment in segments {
            if(segment.range.contains(date: date)) {
                if(try closure(segment)) {
                    return segment
                }
            }
        }
        
        for node in subNodes {
            if(node.range.contains(date: date)) {
                if let segment = try node.firstSegment(on: date, where: closure) {
                    return segment
                }
            }
        }
        
        return nil
    }
    
    /// Recursively queries this task segments node and runs a given block
    /// for every task segment that is overlapping over the given date range.
    ///
    /// The order of the segments is not guaranteed to be ordered.
    ///
    /// - Parameters:
    ///   - range: Range to test against.
    ///   - closure: Closure to execute for every matching task segment found.
    /// - Throws: Rethrows errors from `closure`.
    func querySegments(range: DateRange, with closure: (TaskSegment) throws -> Void) rethrows {
        for segment in segments {
            if(segment.range.intersects(with: range)) {
                try closure(segment)
            }
        }
        
        for node in subNodes {
            if(node.range.intersects(with: range)) {
                try node.querySegments(range: range, with: closure)
            }
        }
    }
    
    /// Iterates all segments of this segments node recursively, depth-first,
    /// calling a given closure for every task segment found.
    ///
    /// The traversal stops when the closure returns `false`.
    ///
    /// - Parameter closure: The closure to use when traversing the task segments.
    /// - Returns: `true` if method returned after complete traversal, or `false`
    /// if `closure` returns false.
    /// - Throws: Rethrows any error from `closure`.
    func iterateAllSegments(with closure: (TaskSegment) throws -> Bool) rethrows -> Bool {
        for segment in segments {
            if(try !closure(segment)) {
                return false
            }
        }
        
        for node in subNodes {
            if(try !node.iterateAllSegments(with: closure)) {
                return false
            }
        }
        
        return true
    }
    
    /// Returns a list of date ranges that covers all the date regions that all
    /// segments cover, by 'flattening' and merging them down into sequential
    /// ranges that are non-intersecting.
    ///
    /// Like `TaskTimelineManager.joinConnectedSegments`, but returns only date
    /// ranges.
    ///
    /// - Returns: List of date ranges that cover the same time regions that the
    /// segments in this segments node do.
    func fastMergeSegmentRanges() -> [DateRange] {
        var ranges: [DateRange] = []
        var currentDate = range.startDate
        
        // Pick first segment, hop to it's end date, and query the segments there
        // If we find one, we jump to that segment's end and repeat until we find
        // an empty gap. When we find a gap, we record the date range of the filled
        // segments we found so far, and repeat until there are no more segments
        // to the right.
        while var nextSegment = closestSegmentLaterThan(date: currentDate, nonEmptyOnly: true) {
            currentDate = nextSegment.range.startDate
            
            var end: Date
            
            repeat {
                end = nextSegment.range.endDate
                
                func nextLongestSegment(on date: Date, in node: SegmentsNode) -> TaskSegment? {
                    var longest: TaskSegment?
                    for segment in node.segments {
                        guard segment.range.contains(date: date), segment.range.endDate > date else {
                            continue
                        }
                        
                        if let long = longest {
                            if segment.range.endDate > long.range.endDate {
                                longest = segment
                            }
                        } else {
                            longest = segment
                        }
                    }
                    
                    let endDate = longest?.range.endDate ?? date
                    for subNode in node.subNodes {
                        guard subNode.range.contains(date: endDate) else {
                            continue
                        }
                        guard let found = nextLongestSegment(on: endDate, in: subNode) else {
                            continue
                        }
                        
                        if let long = longest {
                            if long.range.endDate < found.range.endDate {
                                longest = found
                            }
                        } else {
                            longest = found
                        }
                    }
                    
                    return longest
                }
                
                guard let next = nextLongestSegment(on: end, in: self) else {
                    break
                }
                
                nextSegment = next
            } while true
            
            ranges.append(currentDate...end)
            
            currentDate = nextSegment.range.endDate
        }
        
        return ranges
    }
}

// MARK: - Specific spatial searching
extension SegmentsNode {
    
    /// Return the segment that has the end date closest to the given date,
    /// while also being earlier than it.
    /// Ignores all segments that end _after_ the specified date.
    ///
    /// - Parameter date: Date to search. Must be within this segments node's date
    /// range.
    /// - Returns: Leftmost dated segment that is closest to `date`, while ending
    /// earlier than it.
    func closestSegmentEarlierThan(date: Date, nonEmptyOnly: Bool = false) -> TaskSegment? {
        if(date < range.startDate) {
            return nil
        }
        
        var closest: TaskSegment?
        
        // Start searching from right to left, across all sub-nodes, until we
        // find one that returns a segment that ends before the date.
        for subnode in subNodes.reversed() {
            guard subnode.segmentsCount > 0 else {
                continue
            }
            guard let closestSub = subnode.closestSegmentEarlierThan(date: date) else {
                continue
            }
            
            closest = closestSub
            break
        }
        
        // Search own segments
        for segment in segments {
            if segment.range.timeInterval == 0 && nonEmptyOnly {
                continue
            }
            if segment.range.endDate > date {
                continue
            }
            
            guard let current = closest else {
                closest = segment
                continue
            }
            
            if segment.range.endDate > current.range.endDate {
                closest = segment
            }
        }
        
        return closest
    }
    
    /// Return the segment that has the start date closest to the given date,
    /// while also being later than it.
    /// Ignores all segments that start _before_ the specified date.
    ///
    /// - Parameter date: Date to search. Must be within this segments node's date
    /// range.
    /// - Returns: Leftmost dated segment that is closest to `date`, while staring
    /// later than it.
    func closestSegmentLaterThan(date: Date, nonEmptyOnly: Bool = false) -> TaskSegment? {
        if(date > range.endDate) {
            return nil
        }
        
        var closest: TaskSegment?
        
        // Start searching from left to right, across all sub-nodes, until we
        // find one that returns a segment that starts after the date.
        for subnode in subNodes {
            guard subnode.segmentsCount > 0 else {
                continue
            }
            guard let closestSub = subnode.closestSegmentLaterThan(date: date) else {
                continue
            }
            
            closest = closestSub
            break
        }
        
        // Search own segments
        for segment in segments {
            if segment.range.timeInterval == 0 && nonEmptyOnly {
                continue
            }
            if segment.range.startDate < date {
                continue
            }
            
            guard let current = closest else {
                closest = segment
                continue
            }
            
            if segment.range.startDate < current.range.startDate {
                closest = segment
            }
        }
        
        return closest
    }
}
