//
//  Evaluator.swift
//  TimeCalc
//
//  Created by Luiz Fernando Silva on 06/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

class Evaluator {
    
    enum Result: Equatable, ExpressibleByFloatLiteral, ExpressibleByStringLiteral {
        case time(time: TimeInterval)
        case float(float: Float)
        case string(string: String)
        
        init(floatLiteral value: Float) {
            self = .float(float: value)
        }
        
        init(stringLiteral value: String) {
            self = .string(string: value)
        }
        init(unicodeScalarLiteral value: String) {
            self = .string(string: value)
        }
        init(extendedGraphemeClusterLiteral value: String) {
            self = .string(string: value)
        }
    }
    
    func evaluate(_ typedTree: TypedASTreeNode) -> Result {
        switch(typedTree) {
        case .value(let value, _):
            if case .time(let time) = value.source.tokenType {
                return .time(time: time)
            }
            if case .float(let flt) = value.source.tokenType {
                return .float(float: flt)
            }
            if case .string(let str) = value.source.tokenType {
                return .string(string: str)
            }
            
        case .binaryExpression(let left, let op, let right, _):
            let l = evaluate(left)
            let r = evaluate(right)
            
            return binaryOperation(l, op: op, rhs: r)
            
        case .parenthesizedExpression(let exp, _),
             .unaryExpression(_, let exp, _):
            return evaluate(exp)
        }
        
        return .float(float: 0)
    }
    
    func binaryOperation(_ lhs: Result, op: OperatorType, rhs: Result) -> Result {
        switch(lhs, op, rhs) {
            
        case (.time(let tl), .Addition, .time(let tr)):
            return .time(time: tl + tr)
        case (.time(let tl), .Subtraction, .time(let tr)):
            return .time(time: tl - tr)
        
        case (.float(let il), .Multiplication, .time(let tr)):
            return .time(time: tr * TimeInterval(il))
            
        case (.time(let tl), .Multiplication, .float(let ir)):
            return .time(time: tl * TimeInterval(ir))
            
        case (.time(let tl), .Division, .float(let ir)):
            return .time(time: tl / TimeInterval(ir))
            
        case (.float(let il), .Addition, .float(let ir)):
            return .float(float: il + ir)
        case (.float(let il), .Subtraction, .float(let ir)):
            return .float(float: il - ir)
        case (.float(let il), .Multiplication, .float(let ir)):
            return .float(float: il * ir)
        case (.float(let il), .Division, .float(let ir)):
            return .float(float: il / ir)
            
        case (.time(let tl), .Format, .string(let sl)):
            return .string(string: formatTime(tl, format: sl))
            
        default:
            return .float(float: 0)
        }
    }
    
    func formatTime(_ time: TimeInterval, format: String) -> String {
        if(format.caseInsensitiveCompare("seconds") == .orderedSame) {
            return String(format: "%0.lf", time.rounded(.down))
        }
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        var components = DateComponents()
        
        components.second = Int(time.truncatingRemainder(dividingBy: 60))
        components.minute = Int((time / 60).truncatingRemainder(dividingBy: 60))
        components.hour = Int((time / 60 / 60).truncatingRemainder(dividingBy: 60))
        components.day = Int((time / 60 / 60 / 24))
        
        let date = calendar.date(from: components)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        return formatter.string(from: date)
    }
}

extension Evaluator {
    
    /// Tries to evaluate a given expression, throwing an error if the process fails at any point
    static func evaluate(expression: String) throws -> Evaluator.Result {
        let lexer = Lexer(input: expression)
        let parser = Parser(lexer: lexer)
        
        let parsed = try parser.parse()
        
        let typeResolver = TypeResolver()
        let typedExpression = try typeResolver.resolve(parsed)
        
        let evaluator = Evaluator()
        
        return evaluator.evaluate(typedExpression)
    }
}

func ==(lhs: Evaluator.Result, rhs: Evaluator.Result) -> Bool {
    
    switch(lhs, rhs) {
    case (.float(let l), .float(let r)):
        return l == r
    case (.time(let l), .time(let r)):
        return l == r
    case (.string(let l), .string(let r)):
        return l == r
    default:
        return false
    }
}
