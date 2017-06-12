//
//  TaskManStateConverterTests.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 14/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import TaskMan

class TaskManStateConverterTests: XCTestCase {

    // MARK: Version 1 -> Version 2 conversion
    
    func testVersion1_RunningSegment() {
        // Tests converting a running segment reference to a running segment id on a taskman state
        let runningId: Int = 1
        
        let running: JSON = [
            "range" : [
                "start_date" : "2016-12-14T15:25:16Z",
                "end_date" : "2016-12-14T15:25:16Z"
            ],
            "id" : runningId,
            "task_id" : 1481713862
        ]
        
        let json: JSON = [
            "version": 1,
            "state": [
                "creation_date": "2016-12-14T11:10:59Z",
                "task_list": [
                    "task_segments": [ ],
                    "tasks": [ ]
                ],
                "running_segment": running.object
            ]
        ]
        
        let expected: JSON = [
            "version": 1,
            "state": [
                "creation_date": "2016-12-14T11:10:59Z",
                "task_list": [
                    "task_segments": [ running.object ],
                    "tasks": [ ]
                ],
                "running_segment_id": runningId
            ]
        ]
        
        let converter = TaskManStateConverter()
        
        XCTAssert(converter.canConvertFrom(version: 1))
        
        do {
            let converted = try converter.convert(json: json, fromVersion: 1)
            
            // Assert segment was moved correctly
            XCTAssertEqual(converted["state", "running_segment_id"].int, runningId)
            XCTAssertFalse(converted["state", "running_segment"].exists())
            
            guard let array = converted["state", "task_list", "task_segments"].array else {
                XCTFail("Failed to append task segment correctly")
                return
            }
            
            XCTAssertEqual(array.count, 1)
            XCTAssertEqual(array.first, running)
            
            XCTAssertEqual(converted, expected)
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testVersion1_RunningSegmentNonEmpty() {
        // Tests converting a running segment reference to a running segment id on a taskman state
        // The taskman state already contains a segment, which should also remain.
        
        let runningId: Int = 1
        
        let segment: JSON = [
            "range" : [
                "start_date" : "2016-12-14T15:25:16Z",
                "end_date" : "2016-12-14T15:25:16Z"
            ],
            "id" : runningId + 1,
            "task_id" : 1481713862
        ]
        
        let running: JSON = [
            "range" : [
                "start_date" : "2016-12-14T15:25:16Z",
                "end_date" : "2016-12-14T15:25:16Z"
            ],
            "id" : runningId,
            "task_id" : 1481713862
        ]
        
        let json: JSON = [
            "version": 1,
            "state": [
                "creation_date": "2016-12-14T11:10:59Z",
                "task_list": [
                    "task_segments": [
                        segment.object
                    ],
                    "tasks": [ ]
                ],
                "running_segment": running.object
            ]
        ]
        
        let expected: JSON = [
            "version": 1,
            "state": [
                "creation_date": "2016-12-14T11:10:59Z",
                "task_list": [
                    "task_segments": [
                        segment.object,
                        running.object
                    ],
                    "tasks": [ ]
                ],
                "running_segment_id": runningId
            ]
        ]
        
        let converter = TaskManStateConverter()
        
        XCTAssert(converter.canConvertFrom(version: 1))
        
        do {
            let converted = try converter.convert(json: json, fromVersion: 1)
            
            // Assert segment was moved correctly
            XCTAssertEqual(converted["state", "running_segment_id"].int, runningId)
            XCTAssertFalse(converted["state", "running_segment"].exists())
            
            guard let array = converted["state", "task_list", "task_segments"].array else {
                XCTFail("Failed to append task segment correctly")
                return
            }
            
            // Assert data was appended and is valid now
            XCTAssertEqual(array.count, 2)
            XCTAssertTrue(array.contains(segment))
            XCTAssertTrue(array.contains(running))
            
            XCTAssertEqual(converted, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testVersion1_noRunningSegment() {
        // Tests conversion from version 1 with no running segment associated
        let json: JSON = [
            "version": 1,
            "state": [
                "creation_date": "2016-12-14T11:10:59Z",
                "task_list": [
                    "task_segments": [ ],
                    "tasks": [ ]
                ],
                "running_segment": NSNull()
            ]
        ]
        
        let expected: JSON = [
            "version": 1,
            "state": [
                "creation_date": "2016-12-14T11:10:59Z",
                "task_list": [
                    "task_segments": [ ],
                    "tasks": [ ]
                ],
                "running_segment_id": NSNull()
            ]
        ]
        
        let converter = TaskManStateConverter()
        
        XCTAssert(converter.canConvertFrom(version: 1))
        
        do {
            let converted = try converter.convert(json: json, fromVersion: 1)
            
            // Assert segment was moved correctly
            XCTAssertEqual(converted["state", "running_segment_id"].int, nil)
            XCTAssertFalse(converted["state", "running_segment"].exists())
            
            guard let array = converted["state", "task_list", "task_segments"].array else {
                XCTFail("Failed to generate proper running segment array")
                return
            }
            
            XCTAssertEqual(array.count, 0)
            XCTAssertEqual(converted, expected)
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
