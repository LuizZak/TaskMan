//
//  SegmentsGraph.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 12/06/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import Foundation

/// Protocol for types that provide task segment querying in the form of various
/// helper methods.
protocol TaskSegmentsNodeGraph {
    
    /// Gets the range of this segments node graph
    var range: DateRange { get }
    
    /// Gets all task segments contained within this task segments node graph
    var segments: [TaskSegment] { get }
    
    /// Gets all subnodes of this task segments node graph
    func allSubNodes() -> [Self]
    
    /// Gets all task segments contained within this node graph, and all
    /// child graphs.
    func allSegments() -> [TaskSegment]
    
    /// Gets the maximum depth of this graph node, where in the value returned
    /// is the maximum number of subnodes one can travel before reaching the
    /// bottom-most graph node.
    func maximumDepth() -> Int
    
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
    func querySegments(in range: DateRange, with closure: (TaskSegment) throws -> Void) rethrows
    
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
    
    /// Returns the intersection of a given range on this task segments node
    /// graph's range.
    ///
    /// Returns `nil`, if the given range does not intersect with this node's `range`.
    ///
    /// - Parameter range: Range to limit.
    /// - Returns: input `range`, limited to be within this node's `range` value,
    /// or `nil`, if ranges do not intersect.
    func limitRangeWithinBounds(_ range: DateRange) -> DateRange?
}

extension TaskSegmentsNodeGraph {
    func limitRangeWithinBounds(_ range: DateRange) -> DateRange? {
        return range.intersection(with: range)
    }
    
    func maximumDepth() -> Int {
        if segments.count == 0 {
            return 0
        }
        
        return 1 + (allSubNodes().map { $0.maximumDepth() }.max() ?? 0)
    }
}

/// Quad-tree node structure used to split timeline segments into grid-like regions
/// that get recursively smaller.
///
/// Used to improve performance of tasks that require querying of spacing information
/// of task segments.
final class SegmentsNode: TaskSegmentsNodeGraph {
    private(set) var maxDepth = 6
    private(set) var maxCountBeforeSplit = 10
    
    private(set) weak var parentNode: SegmentsNode?
    
    private(set) var range: DateRange
    private(set) var subNodes: ContiguousArray<SegmentsNode> = []
    private(set) var segments: [TaskSegment] = []
    
    /// Depth of this segment node. 0 means root node
    private(set) var depth: Int = 0
    
    /// Count of segments contained within this segments node, and all sub nodes
    /// combined.
    private(set) var segmentsCount: Int = 0
    
    init(range: DateRange, configuration: Configuration) {
        self.range = range
        
        maxDepth = configuration.maximumDepth
        maxCountBeforeSplit = configuration.maxCountBeforeSplit
        
        segments.reserveCapacity(maxCountBeforeSplit)
    }
    
    convenience init(range: DateRange) {
        self.init(range: range, configuration: Configuration())
    }
    
    convenience init(configuration: Configuration) {
        self.init(range: DateRange(startDate: Date(), endDate: Date()), configuration: configuration)
    }
    
    convenience init(startDate: Date, endDate: Date) {
        self.init(range: startDate...endDate)
    }
    
    convenience init(with segments: [TaskSegment]) {
        let start = segments.earliestSegmentDate() ?? Date()
        let end = segments.latestSegmentDate() ?? Date()
        
        self.init(range: start...end)
        
        for segment in segments {
            insert(segment)
        }
    }
    
    convenience init(with segments: [TaskSegment], range: DateRange) {
        self.init(range: range)
        
        for segment in segments {
            insert(segment)
        }
    }
    
    init() {
        self.range = DateRange(startDate: Date(), endDate: Date())
    }
    
    @discardableResult
    func insertIfFits(_ segment: TaskSegment) -> Bool {
        if !range.contains(range: segment.range) {
            return false
        }
        
        // All paths bellow end up adding a segment
        segmentsCount += 1
        
        if segments.count < maxCountBeforeSplit || depth > maxDepth {
            segments.append(segment)
            return true
        }
        
        subdivide()
        for node in subNodes {
            if node.insertIfFits(segment) {
                return true
            }
        }
        
        segments.append(segment)
        
        return true
    }
    
    func insert(_ segment: TaskSegment) {
        insert([segment])
    }
    
    func insert(_ segments: [TaskSegment]) {
        guard let range = segments.totalRange() else {
            return
        }
        
        if self.range.contains(range: range) {
            for segment in segments {
                precondition(insertIfFits(segment), "Should have succeeded to insert segments")
            }
        } else {
            // Drop all ranges and insert them again
            let totalSegments = allSegments()
            
            removeAllSegments()
            let resetDate = totalSegments.count == 0
            self.segments = []
            
            self.range = resetDate ? range : range.union(with: self.range)
            
            for segment in totalSegments + segments {
                precondition(insertIfFits(segment), "Should have succeeded to insert segments")
            }
        }
    }
    
    /// Flattens the range of this segments so its range reflects the smallest
    /// range possible that fits all segments within.
    ///
    /// Does nothing, if no segments are present.
    func compactRange() {
        if segmentsCount == 0 {
            return
        }
        
        let nodeList = allSegments()
        removeAllSegments()
        subNodes = []
        
        range = nodeList.totalRange() ?? range
        insert(nodeList)
    }
    
    /// Removes all segments, recursively.
    /// Does not reset subnode count.
    private func removeAllSegments() {
        segments = []
        
        for node in subNodes {
            node.removeAllSegments()
        }
    }
    
    /// Searches for a segment within this segments node and removes it.
    ///
    /// - Parameter id: The ID of the segment to remove.
    /// - Returns: Whether the segment was found and removed.
    @discardableResult
    func removeSegment(withId id: TaskSegment.IDType) -> Bool {
        if let index = segments.firstIndex(where: { $0.id == id }) {
            segments.remove(at: index)
            segmentsCount -= 1
            return true
        }
        
        for node in subNodes {
            if node.removeSegment(withId: id) {
                segmentsCount -= 1
                squashEmptySubdivisions()
                return true
            }
        }
        
        return false
    }
    
    /// Searches for all segments within this segments node that match a given
    /// taks ID and removes them.
    ///
    /// - Parameter id: The ID of the task to remove all segments of.
    /// - Returns: All segments that where removed.
    @discardableResult
    func removeSegments(forTaskId id: Task.IDType) -> [TaskSegment] {
        return removeSegments { segment in
            segment.taskId == id
        }
    }
    
    private func removeSegments(where closure: (TaskSegment) throws -> Bool) rethrows -> [TaskSegment] {
        var removed: [TaskSegment] = []
        for (i, segment) in segments.enumerated().reversed() {
            if try closure(segment) {
                segments.remove(at: i)
                removed.append(segment)
            }
        }
        
        segmentsCount -= removed.count
        
        for node in subNodes {
            let subRemoved = try node.removeSegments(where: closure)
            segmentsCount -= subRemoved.count
            
            removed.append(contentsOf: subRemoved)
        }
        
        if removed.count > 0 {
            squashEmptySubdivisions()
        }
        
        return removed
    }
    
    /// Searches for a segment within this segments node, limited to a specified
    /// time range, and removes it.
    ///
    /// - Parameters:
    ///   - id: The ID of the segment to remove.
    ///   - range: Range to limit searching within.
    /// - Returns: Whether the segment was found and removed.
    func removeSegment(withId id: TaskSegment.IDType, within range: DateRange) -> Bool {
        guard let limited = limitRangeWithinBounds(range) else {
            return false
        }
        
        if let index = segments.firstIndex(where: { $0.id == id }) {
            segments.remove(at: index)
            segmentsCount -= 1
            return true
        }
        
        for node in subNodes {
            if (node.range.intersects(with: limited) && node.removeSegment(withId: id)) {
                segmentsCount -= 1
                squashEmptySubdivisions()
                return true
            }
        }
        
        return false
    }
    
    private func subdivide() {
        // Already split
        if subNodes.count > 0 {
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
        if subNodes.count == 0 {
            return
        }
        
        // Verify if any of the sub-nodes is populated still
        for node in subNodes {
            if node.segmentsCount > 0 {
                return
            }
        }
        
        subNodes = []
    }
    
    /// Specifies configurations during the creation of a segments node
    struct Configuration {
        var maximumDepth: Int = 6
        var maxCountBeforeSplit: Int = 10
    }
}

// MARK: - Recursive segments node fetching
extension SegmentsNode {
    
    func allSubNodes() -> [SegmentsNode] {
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
    
    /// Returns all segments stored within this and all descendant nodes sorted
    /// by their starting date.
    func sortedSegments() -> [TaskSegment] {
        return allSegments().sorted { $0.range.startDate < $1.range.startDate }
    }
    
    /// Searches for a segment with a specified ID within this segments graph node.
    /// Searchies this and all sub-nodes recursively.
    ///
    /// - Parameter id: The ID of the segment to search.
    /// - Returns: A segment with a matching segment ID, or nil, if none was found.
    func segment(withId id: TaskSegment.IDType) -> TaskSegment? {
        return firstSegment(where: { $0.id == id })
    }
    
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
        if segmentsCount == 0 {
            return nil
        }
        
        for segment in (reverseSearch ? segments.reversed() : segments) {
            if segment.range.contains(date: date) {
                return segment
            }
        }
        
        if reverseSearch {
            for node in subNodes.reversed() {
                if node.range.contains(date: date) {
                    if let segment = node.segment(on: date) {
                        return segment
                    }
                }
            }
        } else {
            for node in subNodes {
                if node.range.contains(date: date) {
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
        guard let effectiveRange = limitRangeWithinBounds(range) else {
            return 0
        }
        
        var count = 0
        
        for segment in segments {
            if segment.range.intersects(with: effectiveRange) {
                count += 1
            }
        }
        
        for node in subNodes {
            if node.range.intersects(with: effectiveRange) {
                count += node.countOfSegments(intersecting: effectiveRange)
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
        guard let effectiveRange = limitRangeWithinBounds(range) else {
            return []
        }
        
        var array: [TaskSegment] = []
        
        _appendAllSegments(intersecting: effectiveRange, to: &array)
        
        return array
    }
    
    private func _appendAllSegments(intersecting range: DateRange, to array: inout [TaskSegment]) {
        for segment in segments {
            if segment.range.intersects(with: range) {
                array.append(segment)
            }
        }
        
        for node in subNodes {
            if node.range.intersects(with: range) {
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
            if segment.range.contains(date: date) {
                if try closure(segment) {
                    return segment
                }
            }
        }
        
        for node in subNodes {
            if node.range.contains(date: date) {
                if let segment = try node.firstSegment(on: date, where: closure) {
                    return segment
                }
            }
        }
        
        return nil
    }
    
    /// Recursively queries this task segments node and runs a given block
    /// for all task segments contained within this segments node recursively,
    /// then returning the first segment that returns `true` for the closure.
    ///
    /// The order of the segments is not guaranteed to be ordered.
    ///
    /// - Parameter closure: Closure to execute for every matching task segment found.
    /// - Throws: Rethrows errors from `closure`.
    func firstSegment(where closure: (TaskSegment) throws -> Bool) rethrows -> TaskSegment? {
        for segment in segments {
            if try closure(segment) {
                return segment
            }
        }
        
        for node in subNodes {
            if let segment = try node.firstSegment(where: closure) {
                return segment
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
    func querySegments(in range: DateRange, with closure: (TaskSegment) throws -> Void) rethrows {
        guard let effectiveRange = limitRangeWithinBounds(range) else {
            return
        }
        
        for segment in segments {
            if segment.range.intersects(with: effectiveRange) {
                try closure(segment)
            }
        }
        
        for node in subNodes {
            if node.range.intersects(with: effectiveRange) {
                try node.querySegments(in: effectiveRange, with: closure)
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
    @discardableResult
    func iterateAllSegments(with closure: (TaskSegment) throws -> Bool) rethrows -> Bool {
        for segment in segments {
            if try !closure(segment) {
                return false
            }
        }
        
        for node in subNodes {
            if try !node.iterateAllSegments(with: closure) {
                return false
            }
        }
        
        return true
    }
    
    /// Iterates all segments of this segments node recursively within the given
    /// date range, mapping them one-by-one using a passed closure, then returning
    /// the collected values.
    ///
    /// - Parameters:
    ///   - range: Date that segments must be intersecting to be considered for
    /// the mapping.
    ///   - closure: A closure that maps the segments to an output value.
    /// - Returns: All segments mapped with the closure within the range.
    /// - Throws: Rethrows any error from `closure`.
    func mapSegments<T>(in range: DateRange, with closure: (TaskSegment) throws -> T) rethrows -> [T] {
        var values: [T] = []
        
        try querySegments(in: range) { segment in
            try values.append(closure(segment))
        }
        
        return values
    }
    
    /// Returns the earliest starting segment date on this graph.
    ///
    /// - Returns: A date corresponding to the earliest segment's start date on
    /// this graph, or nil, if none was found.
    func earliestSegmentDate() -> Date? {
        if segmentsCount == 0 {
            return nil
        }
        
        let earliestHere = segments.min { $0.range.startDate < $1.range.startDate }?.range.startDate
        
        // If we have an earliest date to start working with, use it to trim the
        // search space- otherwise, make a full sequential search from left to
        // right
        if let earliest = earliestHere {
            let searchRange = DateRange(startDate: range.startDate, endDate: earliest)
            var date = earliest
            
            querySegments(in: searchRange) { segment in
                if segment.range.startDate < date {
                    date = segment.range.startDate
                }
            }
            
            return date
        }
        
        // Perform a simple traversal
        var date: Date?
        
        iterateAllSegments { segment in
            let segmentStart = segment.range.startDate
            
            if date == nil {
                date = segmentStart
            } else if let cur = date, cur > segmentStart {
                date = segmentStart
            }
            
            return true
        }
        
        return date
    }
    
    /// Returns the latest ending segment date on this graph.
    ///
    /// - Returns: A date corresponding to the latest segment's end date on
    /// this graph, or nil, if none was found.
    func latestSegmentDate() -> Date? {
        if segmentsCount == 0 {
            return nil
        }
        
        let latestHere = segments.max { $0.range.endDate < $1.range.endDate }?.range.startDate
        
        // If we have an earliest date to start working with, use it to trim the
        // search space- otherwise, make a full sequential search from left to
        // right
        if let latest = latestHere {
            let searchRange = DateRange(startDate: latest, endDate: range.endDate)
            var date = latest
            
            querySegments(in: searchRange) { segment in
                if segment.range.endDate > date {
                    date = segment.range.endDate
                }
            }
            
            return date
        }
        
        // Perform a simple traversal
        var date: Date?
        
        iterateAllSegments { segment in
            let segmentEnd = segment.range.endDate
            
            if date == nil {
                date = segmentEnd
            } else if let cur = date, cur < segmentEnd {
                date = segmentEnd
            }
            
            return true
        }
        
        return date
    }
}

// MARK: - Spatial querying
extension SegmentsNode {
    
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
        while var nextSegment = closestSegmentStartingLaterThan(date: currentDate, nonEmptyOnly: true) {
            currentDate = nextSegment.range.startDate
            
            var end: Date
            
            repeat {
                end = nextSegment.range.endDate
                
                guard let next = nextLongestSegment(on: end) else {
                    break
                }
                
                nextSegment = next
            } while true
            
            ranges.append(currentDate...end)
            
            currentDate = nextSegment.range.endDate
        }
        
        return ranges
    }
    
    /// Returns the unoccupied ranges between the earliest to latest dates within
    /// this segments graph.
    ///
    /// For example, a node configuration that spans (time is from left to right,
    /// each line is a segment represented in non-specific node depth):
    ///
    ///     - [===]- - - - - - - - - - -
    ///     - - [==] - - - - - [=====] -
    ///     - - - - - -[===] - - - - - -
    ///
    /// results in an empty range composition of:
    ///
    ///     - - - - [=] - - [=]- - - - -
    ///
    func emptySpacesWithinNodes() -> [DateRange] {
        
        // Start at left-most range
        guard let start = closestSegmentStartingLaterThan(date: range.startDate)?.range.startDate else {
            return []
        }
        
        var ranges: [DateRange] = []
        
        var currentDate = start
        var lastEndDate: Date?
        
        while var nextSegment = closestSegmentStartingLaterThan(date: currentDate, nonEmptyOnly: true) {
            if let lastEndDate = lastEndDate {
                ranges.append(lastEndDate...nextSegment.range.startDate)
            }
            
            var end: Date
            
            repeat {
                end = nextSegment.range.endDate
                
                guard let next = nextLongestSegment(on: end) else {
                    break
                }
                
                nextSegment = next
            } while true
            
            currentDate = nextSegment.range.endDate
            lastEndDate = currentDate
        }
        
        return ranges
    }
    
    /// Return the segment that has the end date closest to the given date,
    /// while also being earlier than it.
    /// Ignores all segments that end _after_ the specified date.
    ///
    /// - Parameter date: Date to search. Must be within this segments node's date
    /// range.
    /// - Returns: Leftmost dated segment that is closest to `date`, while ending
    /// earlier than it.
    func closestSegmentEndingEarlierThan(date: Date, nonEmptyOnly: Bool = false) -> TaskSegment? {
        if date < range.startDate {
            return nil
        }
        
        var closest: TaskSegment?
        
        // Start searching from right to left, across all sub-nodes, until we
        // find one that returns a segment that ends before the date.
        for subnode in subNodes.reversed() {
            guard subnode.segmentsCount > 0 else {
                continue
            }
            guard let closestSub = subnode.closestSegmentEndingEarlierThan(date: date) else {
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
            guard segment.range.endDate <= date else {
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
    /// - Parameters
    ///   - date: Date to search. Must be within this segments node's date
    /// range.
    ///   - nonEmptyOnly: If segments with a 0-time interval (i.e. `startDate == endDate`)
    /// are to be ignored during the query.
    /// - Returns: Leftmost dated segment that is closest to `date`, while staring
    /// later than it.
    func closestSegmentStartingLaterThan(date: Date, nonEmptyOnly: Bool = false) -> TaskSegment? {
        // Can't use range.contains(date:) because we also query sub-nodes that
        // have a time interval later than the date, in case we failed to find a
        // segment in an earlier sub-node.
        //
        // If the node has a range ending earlier than the queried date, however,
        // it can't possibly contain a segment that starts later than it (nodes
        // must contain segments that can be entirely fitted within them).
        if date > range.endDate {
            return nil
        }
        
        var closest: TaskSegment?
        
        // Start searching from left to right, across all sub-nodes, until we
        // find one that returns a segment that starts after the date.
        for subnode in subNodes {
            guard subnode.segmentsCount > 0 else {
                continue
            }
            guard let closestSub = subnode.closestSegmentStartingLaterThan(date: date) else {
                continue
            }
            
            closest = closestSub
            // Break - we just won't find a better result going a node to the right
            // because all segments of a node must start on (or later) than its
            // start range date.
            break
        }
        
        // Search own segments
        for segment in segments {
            // Non-empty
            if segment.range.timeInterval == 0 && nonEmptyOnly {
                continue
            }
            guard segment.range.startDate >= date else {
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
    
    // Internal spatial query helper - returns longest segment under a given
    // point
    fileprivate func nextLongestSegment(on date: Date) -> TaskSegment? {
        var longest: TaskSegment?
        for segment in segments {
            guard segment.range.contains(date: date), segment.range.endDate > date else {
                continue
            }
            
            guard let long = longest else {
                longest = segment
                continue
            }
            
            if segment.range.endDate > long.range.endDate {
                longest = segment
            }
        }
        
        let endDate = longest?.range.endDate ?? date
        
        for subNode in subNodes {
            guard subNode.range.contains(date: endDate) else {
                continue
            }
            guard let found = subNode.nextLongestSegment(on: endDate) else {
                continue
            }
            
            guard let long = longest else {
                longest = found
                continue
            }
            
            if long.range.endDate < found.range.endDate {
                longest = found
            }
        }
        
        return longest
    }
}
