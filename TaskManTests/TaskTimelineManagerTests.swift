//
//  TaskTimelineManagerTests.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 24/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import XCTest
@testable import TaskMan

class TaskTimelineManagerTests: XCTestCase {
    
    func testSetDatesChangeDelegate() {
        // Tests that setting new dates to a segment calls the delegate
        // Also tests that trying to modify dates that match the previous dates, no delegate call is made
        
        class Delegate: TaskTimelineManagerDelegate {
            var calls: Int = 0
            
            func taskTimelineManager(_ manager: TaskTimelineManager, didUpdateSegment: TaskSegment) {
                calls += 1
            }
        }
        
        let range = dateRange(start: "2000-01-01 10:00:00", end: "2000-01-01 11:00:00")
        
        let delegate = Delegate()
        let timeline = TaskTimelineManager()
        timeline.delegate = delegate
        
        let id = timeline.createSegment(forTaskId: 1, dateRange: range).id
        
        // Try calling with no changes
        timeline.setSegmentDates(withId: id, startDate: range.startDate, endDate: range.endDate)
        XCTAssertEqual(delegate.calls, 0)
        
        // Try calling with new dates
        timeline.setSegmentDates(withId: id, startDate: range.startDate, endDate: range.endDate + 1)
        XCTAssertEqual(delegate.calls, 1)
    }
    
    func testJoinSegmentsOverlapped() {
        
        let range1 = dateRange(start: "2000-01-01 10:00:00", end: "2000-01-01 11:00:00")
        let range2 = dateRange(start: "2000-01-01 10:00:00", end: "2000-01-01 11:30:00")
        
        let timeline = TaskTimelineManager()
        
        timeline.createSegment(forTaskId: 1, dateRange: range1)
        timeline.createSegment(forTaskId: 1, dateRange: range2)
        
        // Verify segments add up to 02:30
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 2.5)
        
        timeline.joinConnectedSegments(forTaskId: 1)
        
        // Verify now segments add up to 01:30
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 1.5)
        XCTAssertEqual(timeline.segments(forTaskId: 1).count, 1)
    }
    
    func testJoinSegmentsAtEdge() {
        
        let range1 = dateRange(start: "2000-01-01 10:00:00", end: "2000-01-01 11:00:00")
        let range2 = dateRange(start: "2000-01-01 11:00:00", end: "2000-01-01 12:00:00")
        
        let timeline = TaskTimelineManager()
        
        timeline.createSegment(forTaskId: 1, dateRange: range1)
        timeline.createSegment(forTaskId: 1, dateRange: range2)
        
        // Verify segments add up to 02:00
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 2)
        
        timeline.joinConnectedSegments(forTaskId: 1)
        
        // Verify now segments add up to 02:00
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 2)
        XCTAssertEqual(timeline.segments(forTaskId: 1).count, 1)
    }
    
    func testJoinSegmentsAtEdgeMultiple() {
        
        let range1 = dateRange(start: "2000-01-01 10:00:00", end: "2000-01-01 11:00:00")
        let range2 = dateRange(start: "2000-01-01 11:00:00", end: "2000-01-01 12:00:00")
        let range3 = dateRange(start: "2000-01-01 12:00:00", end: "2000-01-01 13:00:00")
        
        let timeline = TaskTimelineManager()
        
        timeline.createSegment(forTaskId: 1, dateRange: range1)
        timeline.createSegment(forTaskId: 1, dateRange: range2)
        timeline.createSegment(forTaskId: 1, dateRange: range3)
        
        // Verify segments add up to 02:00
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 3)
        
        timeline.joinConnectedSegments(forTaskId: 1)
        
        // Verify now segments add up to 02:00
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 3)
        XCTAssertEqual(timeline.segments(forTaskId: 1).count, 1)
    }
    
    func testJoinSegmentsNoInterception() {
        
        let range1 = dateRange(start: "2000-01-01 10:00:00", end: "2000-01-01 11:00:00")
        let range2 = dateRange(start: "2000-01-01 12:00:00", end: "2000-01-01 13:00:00")
        
        let timeline = TaskTimelineManager()
        
        timeline.createSegment(forTaskId: 1, dateRange: range1)
        timeline.createSegment(forTaskId: 1, dateRange: range2)
        
        // Verify segments add up to 02:00
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 2)
        
        timeline.joinConnectedSegments(forTaskId: 1)
        
        // Verify segments are still the same
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 2)
        XCTAssertEqual(timeline.segments(forTaskId: 1).count, 2)
    }
    
    func testTotalTimeOverlapping() {
        /// Tests that trying to fetch total time of segments that are overlapping results
        /// in a total time that ignores any overlapt time range
        
        let range1 = dateRange(start: "2000-01-01 10:00:00", end: "2000-01-01 11:30:00")
        let range2 = dateRange(start: "2000-01-01 11:00:00", end: "2000-01-01 12:30:00")
        
        let timeline = TaskTimelineManager()
        
        timeline.createSegment(forTaskId: 1, dateRange: range1)
        timeline.createSegment(forTaskId: 1, dateRange: range2)
        
        // Verify segments add up to 03:00
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 1.5 * 2)
        XCTAssertEqual(timeline.totalTime(forTaskId: 1, withOverlap: true), 3600 * 1.5 * 2)
        // Verify total time ignores overlapped 30 minutes between segments
        XCTAssertEqual(timeline.totalTime(forTaskId: 1), 3600 * 2.5)
    }
    
    func testTotalTimeOverlappingSequential() {
        /// Tests that trying to fetch total time of segments that are overlapping results
        /// in a total time that ignores any overlapt time range
        
        let range1 = dateRange(start: "2000-01-01 10:00:00", end: "2000-01-01 11:30:00")
        let range2 = dateRange(start: "2000-01-01 11:00:00", end: "2000-01-01 12:30:00")
        let range3 = dateRange(start: "2000-01-01 12:00:00", end: "2000-01-01 13:30:00")
        let range4 = dateRange(start: "2000-01-01 13:00:00", end: "2000-01-01 14:30:00")
        
        let timeline = TaskTimelineManager()
        
        timeline.createSegment(forTaskId: 1, dateRange: range1)
        timeline.createSegment(forTaskId: 1, dateRange: range2)
        timeline.createSegment(forTaskId: 1, dateRange: range3)
        timeline.createSegment(forTaskId: 1, dateRange: range4)
        
        // Verify segments add up to 05:00
        XCTAssertEqual(timeline.segments(forTaskId: 1).intervalSum(), 3600 * 1.5 * 4)
        XCTAssertEqual(timeline.totalTime(forTaskId: 1, withOverlap: true), 3600 * 1.5 * 4)
        // Verify total time ignores overlapped 2 hours between segments
        XCTAssertEqual(timeline.totalTime(forTaskId: 1), 3600 * 4.5)
    }
    
    func testTotalTimeNoOverlapPerformance() {
        let count = 10_000
        
        let timeline = TaskTimelineManager()
        var segments: [TaskSegment] = []
        segments.reserveCapacity(count)
        
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        // Add segments that start 30m appart each other, while growing by one hour
        // each (1h, 2h, 3h, 4h etc...).
        for i in 0..<count {
            let time = TimeInterval(i)
            
            let start = startDate + (time * 1800) // 30m
            let end = start + (time * 3600)
            
            segments.append(TaskSegment(id: i, taskId: 1, range: start...end))
        }
        
        timeline.addSegments(segments)
        
        measure {
            XCTAssertEqual(timeline.totalTime(forTaskId: 1, withOverlap: false), 53992800.0)
        }
    }
    
    func testTotalTimeNoOverlapPerformanceSequentialOverlaps() {
        let count = 10_000
        
        let timeline = TaskTimelineManager()
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
        
        timeline.addSegments(segments)
        
        measure {
            XCTAssertEqual(timeline.totalTime(forTaskId: 1, withOverlap: false), 18001800.0)
        }
    }
    
    func testTotalTimeNoOverlapPerformanceWithGaps() {
        let count = 10_000
        
        let timeline = TaskTimelineManager()
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
        
        timeline.addSegments(segments)
        
        measure {
            XCTAssertEqual(timeline.totalTime(forTaskId: 1, withOverlap: false), 36000000.0)
        }
    }
    
    func testTotalTimeWithOverlapPerformance() {
        let count = 100_000
        
        let timeline = TaskTimelineManager()
        var segments: [TaskSegment] = []
        segments.reserveCapacity(count)
        
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        // Add 1h segments sequentially, overlapping accross one another over 30m each
        for i in 0..<count {
            let time = TimeInterval(i)
            
            let start = startDate + (time * 1800) // 30m
            let end = start + (time * 3600)
            
            segments.append(TaskSegment(id: i, taskId: 1, range: start...end))
        }
        
        timeline.addSegments(segments)
        
        measure {
            XCTAssertEqual(timeline.totalTime(forTaskId: 1, withOverlap: true), 17999820000000)
        }
    }
    
    func testTotalTimeWithOverlapPerformanceSequentialOverlaps() {
        let count = 100_000
        
        let timeline = TaskTimelineManager()
        var segments: [TaskSegment] = []
        segments.reserveCapacity(count)
        
        let startDate = dateFromTimestamp("2000-01-01 01:00:00")
        
        // Add 1h segments sequentially, overlapping accross one another over 30m each
        for i in 0..<count {
            let time = TimeInterval(i)
            
            let start = startDate + (time * 1800) // 30m
            let end = start + 3600
            
            segments.append(TaskSegment(id: i, taskId: 1, range: start...end))
        }
        
        timeline.addSegments(segments)
        
        measure {
            XCTAssertEqual(timeline.totalTime(forTaskId: 1, withOverlap: true), 360000000.0)
        }
    }
    
    fileprivate func dateFromTimestamp(_ timestamp: String) -> Date {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return formatter.date(from: timestamp)!
    }
    
    fileprivate func dateRange(start: String, end: String) -> DateRange {
        return DateRange(startDate: dateFromTimestamp(start), endDate: dateFromTimestamp(end))
    }
}

