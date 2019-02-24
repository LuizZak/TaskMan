//
//  Coding.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 24/02/19.
//  Copyright © 2019 Luiz Fernando Silva. All rights reserved.
//

import Foundation

func makeDefaultJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.keyEncodingStrategy = .convertToSnakeCase
    
    return encoder
}

func makeDefaultJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    return decoder
}
