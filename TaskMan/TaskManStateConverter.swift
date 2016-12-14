//
//  TaskManStateConverter.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 14/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

/// Private helper class used to help convert files from previous versions of TaskMan
class TaskManStateConverter {
    
    /// Returns whether the given file version can be converted to the newest compatible format
    func canConvertFrom(version: Int) -> Bool {
        if(version == 1) {
            return true
        }
        
        return version == FileFormatVersion
    }
    
    /// Converts the given JSON structure to the newest compatible format
    func convert(json: JSON, fromVersion version: Int) throws -> JSON {
        var json = json
        if(version == 1) {
            // Pull running segment from the taskman state body to the list of running segments, and then
            // attach the segment ID to the json instead
            let segment = json["state", "running_segment"]
            if !(segment.object is NSNull) {
                // Push object to the segments list
                let path = ["state", "task_list", "task_segments"]
                json[path].object = json[path].array.map { $0 + [segment] } ?? [segment]
            }
            
            let id = try segment["id"].tryInt()
            
            json["state", "running_segment_id"].int = id
            
            // Remove segment key
            json["state"].object = json["state"].dictionaryObject.flatMap {
                var dict = $0
                dict.removeValue(forKey: "running_segment")
                return dict
            } ?? [:]
        }
        
        return json
    }
}
