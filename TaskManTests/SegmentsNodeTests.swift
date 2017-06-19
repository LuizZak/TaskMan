//
//  SegmentsNodeTests.swift
//  TaskManTests
//
//  Created by Luiz Fernando Silva on 12/06/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import XCTest
@testable import TaskMan

extension TimeInterval {
    var seconds: TimeInterval {
        return self
    }
    
    var minutes: TimeInterval {
        return seconds * 60
    }
    
    var hours: TimeInterval {
        return minutes * 60
    }
}

class SegmentsNodeTests: XCTestCase {
    
    var nextSegId = 1
    
    override func setUp() {
        super.setUp()
        
        nextSegId = 1
    }
    
    func testAddSegments() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        let node = SegmentsNode()
        
        let seg1 = segWithDates(startDate, startDate + 1.hours)
        let seg2 = segWithDates(startDate + 2.hours, startDate + 3.hours)
        
        node.insert(seg1)
        node.insert(seg2)
        
        XCTAssertEqual(node.segments.count, 2)
    }
    
    func testRemoveSegment() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        let node = SegmentsNode()
        
        let seg1 = segWithDates(startDate, startDate + 1.hours)
        let seg2 = segWithDates(startDate + 2.hours, startDate + 3.hours)
        
        node.insert(seg1)
        node.insert(seg2) // id: 2
        
        node.removeSegment(withId: 2)
        
        XCTAssertEqual(node.segments.count, 1)
    }
    
    func testCompact() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        let node = SegmentsNode()
        
        let seg1 = segWithDates(startDate, startDate + 1.hours)
        let seg2 = segWithDates(startDate + 2.hours, startDate + 3.hours)
        
        node.insert(seg1)
        node.insert(seg2) // id: 2
        
        let range = startDate...startDate + 3.hours
        XCTAssertEqual(node.range, range)
        
        node.removeSegment(withId: 2)
        node.compactRange()
        
        let rangeAfter = startDate...startDate + 1.hours
        XCTAssertEqual(node.range, rangeAfter)
    }
    
    func testSubNodeCount() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        let config = SegmentsNode.Configuration(maximumDepth: 2, maxCountBeforeSplit: 2)
        let node = SegmentsNode(configuration: config)
        
        let fullRange = DateRange(startDate: startDate, endDate: startDate + 5.hours)
        let eightRange = DateRange(startDate: startDate, endDate: startDate + (5.hours / 8))
        
        // Keep inserting until split
        node.insert(segWithRange(fullRange))
        node.insert(segWithRange(fullRange))
        
        // Insert eight
        node.insert(segWithRange(eightRange)) // id: 3
        node.insert(segWithRange(eightRange))
        
        XCTAssertEqual(node.segments.count, 2)
        XCTAssertEqual(node.segmentsCount, 4)
        
        node.removeSegment(withId: 3)
        
        XCTAssertEqual(node.segments.count, 2)
        XCTAssertEqual(node.segmentsCount, 3)
    }
    
    func testSubNodeCountAfterRemovalByTaskId() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        let config = SegmentsNode.Configuration(maximumDepth: 2, maxCountBeforeSplit: 2)
        let node = SegmentsNode(configuration: config)
        
        let fullRange = DateRange(startDate: startDate, endDate: startDate + 5.hours)
        let eightRange = DateRange(startDate: startDate, endDate: startDate + (5.hours / 8))
        
        // Keep inserting until split
        node.insert(segWithRange(fullRange, taskId: 1))
        node.insert(segWithRange(fullRange, taskId: 1))
        
        // Insert eight
        node.insert(segWithRange(eightRange, taskId: 2))
        node.insert(segWithRange(eightRange, taskId: 2))
        
        XCTAssertEqual(node.removeSegments(forTaskId: 2).count, 2)
        
        XCTAssertEqual(node.segments.count, 2)
        XCTAssertEqual(node.segmentsCount, 2)
    }
    
    func testEmptySpaceRanges() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        let node = SegmentsNode()
        
        let seg1 = segWithDates(startDate, startDate + 1.hours)
        let seg2 = segWithDates(startDate + 2.hours, startDate + 3.hours)
        let seg3 = segWithDates(startDate + 4.hours, startDate + 6.hours)
        
        node.insert([seg1, seg2, seg3])
        
        let empty = node.emptySpacesWithinNodes()
        
        XCTAssertEqual(empty.count, 2)
        XCTAssertEqual(empty[0], seg1.range.endDate...seg2.range.startDate)
        XCTAssertEqual(empty[1], seg2.range.endDate...seg3.range.startDate)
    }
    
    func testEmptySpaceRangesWithCompleteOverlap() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        let node = SegmentsNode()
        
        let seg1 = segWithDates(startDate, startDate + 2.5.hours)
        let seg2 = segWithDates(startDate + 2.hours, startDate + 5.hours)
        let seg3 = segWithDates(startDate + 4.hours, startDate + 6.hours)
        
        node.insert([seg1, seg2, seg3])
        
        let empty = node.emptySpacesWithinNodes()
        
        XCTAssertEqual(empty.count, 0)
    }
    
    func testEmptySpaceRangesWithEmptySegments() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        let node = SegmentsNode()
        
        let seg1 = segWithDates(startDate, startDate + 1.hours)
        let seg2 = segWithDates(startDate + 2.hours, startDate + 3.hours)
        let seg3 = segWithDates(startDate + 2.5.hours, startDate + 2.5.hours)
        let seg4 = segWithDates(startDate + 4.hours, startDate + 6.hours)
        
        node.insert([seg1, seg2, seg3, seg4])
        
        let empty = node.emptySpacesWithinNodes()
        
        XCTAssertEqual(empty.count, 2)
        XCTAssertEqual(empty[0], seg1.range.endDate...seg2.range.startDate)
        XCTAssertEqual(empty[1], seg2.range.endDate...seg4.range.startDate)
    }
    
    func testSortedSegments() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        let endDate = dateFromTimestamp("2000-02-01 01:00:00")
        
        let count = 10_000
        
        let node = SegmentsNode()
        var segments: [TaskSegment] = []
        segments.reserveCapacity(count)
        
        // Add segments randomly spanning a pre-determined range
        for i in 0..<count {
            let date1 = startDate + TimeInterval(arc4random_uniform(UInt32(endDate.timeIntervalSince(startDate))))
            let date2 = startDate + TimeInterval(arc4random_uniform(UInt32(endDate.timeIntervalSince(startDate))))
            
            segments.append(TaskSegment(id: i, taskId: 1, range: min(date1, date2)...max(date1, date2)))
        }
        
        node.insert(segments)
        
        let expected = segments.sorted { $0.range.startDate < $1.range.startDate }
        let result = node.sortedSegments()
        
        XCTAssert(expected.elementsEqual(result, by: { $0.range.startDate == $1.range.startDate }))
    }
    
    func testSortedSegmentsPerformance() {
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        let endDate = dateFromTimestamp("2000-02-01 01:00:00")
        
        let count = 10_000
        
        let node = SegmentsNode()
        var segments: [TaskSegment] = []
        segments.reserveCapacity(count)
        
        // Add segments spanning across a range
        for i in 0..<count {
            let date1 = startDate + TimeInterval(arc4random_uniform(UInt32(endDate.timeIntervalSince(startDate))))
            let date2 = startDate + TimeInterval(arc4random_uniform(UInt32(endDate.timeIntervalSince(startDate))))
            
            segments.append(TaskSegment(id: i, taskId: 1, range: min(date1, date2)...max(date1, date2)))
        }
        
        node.insert(segments)
        
        measure {
            _=node.sortedSegments()
        }
    }
    
    func testEmptyDateRangesPerformanceWithGapsCoveredWithLongRange() {
        let count = 10_000
        
        let node = SegmentsNode()
        var segments: [TaskSegment] = []
        segments.reserveCapacity(count)
        
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        // Add segments that have 30m of gap between each other and have 1h of
        // duration each.
        for i in 0..<count {
            let time = TimeInterval(i)
            
            let start = startDate + (time * 5400)
            let end = start + 3600
            
            segments.append(TaskSegment(id: i, taskId: 1, range: start...end))
        }
        
        // Add a segment that completely covers all segments above
        let endRange = startDate + (TimeInterval(count - 1) * 5400) + 3600
        
        // Inset interval by 1 second on each end so the first and last segments
        // are actually 1h segments. The fast path should then kick in and hop
        // using the large segment that covers almost end-to-end all the segments
        segments.append(TaskSegment(id: count + 1, taskId: 1, range: (startDate + 1)...endRange - 1))
        
        node.insert(segments)
        
        measure {
            XCTAssertEqual(node.emptySpacesWithinNodes().count, 0)
        }
    }
    
    func testEmptyDateRangesPerformanceWithGaps() {
        let count = 10_000
        
        let node = SegmentsNode()
        var segments: [TaskSegment] = []
        segments.reserveCapacity(count)
        
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        // Add segments that have 30m of gap between each other and have 1h of
        // duration each.
        for i in 0..<count {
            let time = TimeInterval(i)
            
            let start = startDate + (time * 5400)
            let end = start + 3600
            
            segments.append(TaskSegment(id: i, taskId: 1, range: start...end))
        }
        
        node.insert(segments)
        
        measure {
            XCTAssertEqual(node.emptySpacesWithinNodes().count, count - 1)
        }
    }
    
    func testEmptyDateRangesPerformanceCompletelyFilled() {
        let count = 10_000
        
        let node = SegmentsNode()
        var segments: [TaskSegment] = []
        segments.reserveCapacity(count)
        
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        // Add 1h segments sequentially, overlapping accross one another over 30m each
        for i in 0..<count {
            let time = TimeInterval(i) / 2
            
            let start = startDate + (time * 3600)
            let end = start + 3600
            
            segments.append(TaskSegment(id: i, taskId: 1, range: start...end))
        }
        
        node.insert(segments)
        
        measure {
            XCTAssertEqual(node.emptySpacesWithinNodes().count, 0)
        }
    }
    
    func segWithDates(_ start: Date, _ end: Date, _ id: Int? = nil, taskId: Int? = nil) -> TaskSegment {
        return segWithRange(start...end, id)
    }
    
    func segWithRange(_ range: DateRange, _ id: Int? = nil, taskId: Int? = nil) -> TaskSegment {
        defer {
            if id == nil {
                nextSegId += 1
            }
        }
        return TaskSegment(id: id ?? nextSegId, taskId: taskId ?? 1, range: range)
    }
    
    func dateFromTimestamp(_ timestamp: String) -> Date {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return formatter.date(from: timestamp)!
    }
}
