//
//  DateRange+Serialization.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 07/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import SwiftyJSON

extension DateRange: JsonInitializable, JsonSerializable {
    init(json: JSON) throws {
        try self.startDate = json[JsonKey.startDate].tryParseDate(withFormatter: rfc3339DateTimeFormatter)
        try self.endDate = json[JsonKey.endDate].tryParseDate(withFormatter: rfc3339DateTimeFormatter)
    }
    
    func serialize() -> JSON {
        var dict: [JsonKey: Any] = [:]
        
        dict[.startDate] = rfc3339StringFrom(date: startDate)
        dict[.endDate] = rfc3339StringFrom(date: endDate)
        
        return dict.mapToJSON()
    }
}

extension DateRange {
    
    /// Inner enum containing the JSON key names for the model
    enum JsonKey: String, JSONSubscriptType {
        case startDate = "start_date"
        case endDate = "end_date"
        
        var jsonKey: JSONKey {
            return JSONKey.key(self.rawValue)
        }
    }
}
