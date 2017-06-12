//
//  SegmentsGraph.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 12/06/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

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

extension TaskSegmentsNodeGraph {
    func maximumDepth() -> Int {
        if segments.count == 0 {
            return 0
        }
        
        return 1 + (allSubNodes().map { $0.maximumDepth() }.max() ?? 0)
    }
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
        if segmentsCount == 0 {
            return nil
        }
        
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
        while var nextSegment = closestSegmentStartingLaterThan(date: currentDate, nonEmptyOnly: true) {
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
    func closestSegmentEndingEarlierThan(date: Date, nonEmptyOnly: Bool = false) -> TaskSegment? {
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
            guard let closestSub = subnode.closestSegmentStartingLaterThan(date: date) else {
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

