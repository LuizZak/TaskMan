//
//  DateRangeTests.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 07/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import XCTest

class DateRangeTests: XCTestCase {
    
    func testIntersects() {
        // Intersecting inside
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 2), endDate: Date(timeIntervalSince1970: 8))
            
            XCTAssert(dateRange1.intersects(with: dateRange2))
        }
        
        // Intersecting at the edges
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 10), endDate: Date(timeIntervalSince1970: 20))
            
            XCTAssert(dateRange1.intersects(with: dateRange2))
        }
        
        // Non-intersecting
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 11), endDate: Date(timeIntervalSince1970: 20))
            
            XCTAssertFalse(dateRange1.intersects(with: dateRange2))
        }
    }
    
    func testIntersection() {
        // Intersecting inside
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 2), endDate: Date(timeIntervalSince1970: 8))
            
            XCTAssertEqual(dateRange1.intersection(with: dateRange2), dateRange2)
        }
        
        // Intersecting outside
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 9), endDate: Date(timeIntervalSince1970: 20))
            
            let expected = DateRange(startDate: Date(timeIntervalSince1970: 9), endDate: Date(timeIntervalSince1970: 10))
            
            XCTAssertEqual(dateRange1.intersection(with: dateRange2), expected)
        }
        
        // Intersecting at edges
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 10), endDate: Date(timeIntervalSince1970: 20))
            
            XCTAssertNil(dateRange1.intersection(with: dateRange2))
        }
        
        // Non-intersecting
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 20), endDate: Date(timeIntervalSince1970: 30))
            
            XCTAssertNil(dateRange1.intersection(with: dateRange2))
        }
    }
    
    func testUnion() {
        // Union inside
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 2), endDate: Date(timeIntervalSince1970: 8))
            
            XCTAssertEqual(dateRange1.union(with: dateRange2), dateRange1)
        }
        
        // Union intersecting
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 8), endDate: Date(timeIntervalSince1970: 20))
            
            let expected = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 20))
            
            XCTAssertEqual(dateRange1.union(with: dateRange2), expected)
        }
        
        // Union outside
        do {
            let dateRange1 = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 10))
            let dateRange2 = DateRange(startDate: Date(timeIntervalSince1970: 20), endDate: Date(timeIntervalSince1970: 30))
            
            let expected = DateRange(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 30))
            
            XCTAssertEqual(dateRange1.union(with: dateRange2), expected)
        }
    }
}
