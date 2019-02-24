//
//  TypeResolver.swift
//  TimeCalc
//
//  Created by Luiz Fernando Silva on 02/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Foundation

/// Class capable of resolving types of ASTreeNode objects
final class TypeResolver {
    
    func resolve(_ tree: ASTreeNode) throws -> TypedASTreeNode {
        switch(tree) {
        case .invalidAST:
            throw TypeResolverError.invalidASTInSource
            
        case .unaryExpression(let op, let value):
            let expRes = try resolve(value)
            
            return .unaryExpression(operator: op, value: expRes, type: valueTypeFromTree(expRes))
            
        case .parenthesizedExpression(let expression):
            let expRes = try resolve(expression)
            
            return TypedASTreeNode.parenthesizedExpression(expression: expRes, type: valueTypeFromTree(expRes))
            
        case .value(let value):
            return TypedASTreeNode.value(value: value, type: resolveValue(value))
            
        case .binaryExpression(let left, let op, let right):
            let leftTyped = try resolve(left)
            let rightTyped = try resolve(right)
            
            let result = resolveBinary(valueTypeFromTree(leftTyped), op: op, rhs: valueTypeFromTree(rightTyped))
            
            return TypedASTreeNode.binaryExpression(leftValue: leftTyped, operator: op, rightValue: rightTyped, type: result)
        }
    }
    
    func valueTypeFromTree(_ tree: TypedASTreeNode) -> ASTreeValueType {
        switch(tree) {
        case .value(_, let type):
            return type
            
        case .parenthesizedExpression(_, let type):
            return type
            
        case .unaryExpression(_, _, let type):
            return type
            
        case .binaryExpression(_, _, _, let type):
            return type
        }
    }
    
    func resolveBinary(_ lhs: ASTreeValueType, op: OperatorType, rhs: ASTreeValueType) -> ASTreeValueType {
        switch(lhs, op, rhs) {
        // Invalid types propagate
        case (_, _, .invalid(let msg)):
            return .invalid(message: msg)
        case (.invalid(let msg), _, _):
            return .invalid(message: msg)
            
        case (let left, OperatorType.Format, let right):
            // Only allow string formattings
            guard case .string = right else {
                return .invalid(message: "Expected format string on right side of formatting '>' operator")
            }
            guard case .time = left else {
                return .invalid(message: "Expected time value on left side of formatting '>' operator")
            }
            
            return right
            
        // Any known operation on integers results in integers
        case (ASTreeValueType.float, _, ASTreeValueType.float):
            return .float
            
        // Can subtract/add time to time
        case (ASTreeValueType.time, OperatorType.Addition, ASTreeValueType.time),
             (ASTreeValueType.time, OperatorType.Subtraction, ASTreeValueType.time):
            return .time
        
        // Can multiply and divide time by integer (cannot sum or subtract, though!)
        case (ASTreeValueType.time, OperatorType.Division, ASTreeValueType.float),
             (ASTreeValueType.time, OperatorType.Multiplication, ASTreeValueType.float),
             (ASTreeValueType.float, OperatorType.Multiplication, ASTreeValueType.time):
            return .time
        
        // Cannot divide or multiply time by time!
        case (ASTreeValueType.time, OperatorType.Division, ASTreeValueType.time),
             (ASTreeValueType.time, OperatorType.Multiplication, ASTreeValueType.time):
            return .invalid(message: "Cannot divide or multiply time quantities between themselves")
            
        // Cannot divide or multiply integer by time!
        case (ASTreeValueType.float, OperatorType.Division, ASTreeValueType.time):
            return .invalid(message: "Cannot divide numbers by time quantities")
            
        // Cannot add or subtract time from integer or integer from time!
        case (ASTreeValueType.float, OperatorType.Addition, ASTreeValueType.time),
             (ASTreeValueType.float, OperatorType.Subtraction, ASTreeValueType.time),
             (ASTreeValueType.time, OperatorType.Addition, ASTreeValueType.float),
             (ASTreeValueType.time, OperatorType.Subtraction, ASTreeValueType.float):
            return .invalid(message: "Cannot add or subtract with numbers and time quantities")
            
        default:
            return ASTreeValueType.invalid(message: "Cannot apply operator \(op.rawValue) between values of type \(valueName(lhs)) and \(valueName(rhs))")
        }
    }
    
    func resolveValue(_ value: ASTreeValue) -> ASTreeValueType {
        do {
            let lexer = Lexer(input: value.rawString)
            let peek = try lexer.peek()
            if lexer.isStringDelimiter(peek) {
                return .string
            }
            _ = try lexer.parseFloatString()
            if lexer.isEof() {
                return .float
            } else {
                return .time
            }
        } catch {
            return ASTreeValueType.unknown
        }
    }
    
    func valueName(_ valueType: ASTreeValueType) -> String {
        switch(valueType) {
        case .float:
            return "float"
        case .time:
            return "time"
        case .string:
            return "string"
        case .unknown, .invalid:
            return "unknown"
        }
    }
    
    enum TypeResolverError: Error {
        // Invalid AST in source
        case invalidASTInSource
    }
}
