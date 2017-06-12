//
//  ASTree.swift
//  TimeCalc
//
//  Created by Luiz Fernando Silva on 19/10/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation

enum ASTreeValueType {
    case unknown
    case invalid(message: String)
    case time
    case float
    case string
}

struct ASTreeValue {
    var rawString: String
    var type: ASTreeValueType
    var source: Token
}

indirect enum TypedASTreeNode {
    case unaryExpression(operator: OperatorType, value: TypedASTreeNode, type: ASTreeValueType)
    case parenthesizedExpression(expression: TypedASTreeNode, type: ASTreeValueType)
    case binaryExpression(leftValue: TypedASTreeNode, operator: OperatorType, rightValue: TypedASTreeNode, type: ASTreeValueType)
    case value(value: ASTreeValue, type: ASTreeValueType)
    
    /// Fetches the value type for this TypedASTreeNode.
    func valueType() -> ASTreeValueType {
        switch(self) {
        case .unaryExpression(_, _, let type):
            return type
            
        case .parenthesizedExpression(_, let type):
            return type
            
        case .binaryExpression(_, _, _, let type):
            return type
            
        case .value(_, let type):
            return type
        }
    }
    
    /// Gets the source range for this node. In case this is a complex recursive expression (e.g. a binary expression),
    /// it returns the entire range of the expression's inner components.
    func sourceRange() -> Range<String.Index> {
        switch(self) {
        case .value(let value, _):
            return value.source.inputRange
            
        case .binaryExpression(let left, _, let right, _):
            let lr = left.sourceRange(), rr = right.sourceRange()
            
            return (lr.lowerBound..<rr.upperBound)
            
        case .unaryExpression(_, let node, _):
            return node.sourceRange()
            
        case .parenthesizedExpression(let node, _):
            return node.sourceRange()
        }
    }
    
    /// Returns the entire complex string resulting from collapsing this expression.
    func stringRepresentation() -> String {
        switch(self) {
        case .value(let value, _):
            return value.source.tokenString
            
        case .binaryExpression(let left, let op, let right, _):
            let lstring = left.stringRepresentation(), rstring = right.stringRepresentation()
            
            return "\(lstring)\(op.rawValue)\(rstring)"
            
        case .unaryExpression(let op, let node, _):
            return "\(op.rawValue)\(node.stringRepresentation())"
            
        case .parenthesizedExpression(let node, _):
            return "(\(node.stringRepresentation()))"
        }
    }
    
    /// Returns the entire complex string resulting from collapsing this expression, on top of a given source string.
    func sourceString(onString string: String) -> String {
        return string[sourceRange()]
    }
}

indirect enum ASTreeNode {
    case invalidAST(error: String)
    case unaryExpression(operator: OperatorType, value: ASTreeNode)
    case parenthesizedExpression(expression: ASTreeNode)
    case binaryExpression(leftValue: ASTreeNode, operator: OperatorType, rightValue: ASTreeNode)
    case value(value: ASTreeValue)
    
    /// Returns whether this node is a BinaryExpression case enum
    func isBinaryExpression() -> Bool {
        if case .binaryExpression = self {
            return true
        }
        
        return false
    }
    
    /// Rotates this ASTreeNode left, in case it's a binary expression.
    /// The right side of the tree has to be a binary expression tree as well
    /// In case it is not, no operation is performed.
    func rotateLeft() -> ASTreeNode {
        guard case .binaryExpression(let left, let op, let right) = self else {
            return self
        }
        guard case .binaryExpression(let rLeft, let rOp, let rRight) = right else {
            return self
        }
        
        let newLeft = ASTreeNode.binaryExpression(leftValue: left, operator: op, rightValue: rLeft)
        
        return .binaryExpression(leftValue: newLeft, operator: rOp, rightValue: rRight)
    }
    
    /// Rotates this ASTreeNode right, in case it's a binary expression.
    /// In case it is not, no operation is performed
    func rotateRight() -> ASTreeNode {
        guard case .binaryExpression(let left, let op, let right) = self else {
            return self
        }
        guard case .binaryExpression(let lLeft, let lOp, let lRight) = left else {
            return self
        }
        
        let newRight = ASTreeNode.binaryExpression(leftValue: lRight, operator: op, rightValue: right)
        
        return .binaryExpression(leftValue: lLeft, operator: lOp, rightValue: newRight)
    }
    
    /// Gets the source range for this node. In case this is a complex recursive expression (e.g. a binary expression),
    /// it returns the entire range of the expression's inner components.
    /// In case this is an invalid tree node, nil is returned
    func sourceRange() -> Range<String.Index>? {
        switch(self) {
        case .value(let value):
            return value.source.inputRange
            
        case .binaryExpression(let left, _, let right):
            guard let lr = left.sourceRange(), let rr = right.sourceRange() else {
                return nil
            }
            
            return (lr.lowerBound..<rr.upperBound)
            
        case .unaryExpression(_, let node):
            return node.sourceRange()
            
        case .parenthesizedExpression(let node):
            return node.sourceRange()
            
        case .invalidAST:
            return nil
        }
    }
    
    /// Returns the entire complex string resulting from collapsing this expression.
    /// Returns nil, if it's an invalid tree.
    func stringRepresentation() -> String? {
        switch(self) {
        case .value(let value):
            return value.source.tokenString
            
        case .binaryExpression(let left, let op, let right):
            guard let lstring = left.stringRepresentation(), let rstring = right.stringRepresentation() else {
                return nil
            }
            
            return "\(lstring)\(op.rawValue)\(rstring)"
            
        case .unaryExpression(let op, let node):
            return "\(op.rawValue)\(String(describing: node.stringRepresentation()))"
            
        case .parenthesizedExpression(let node):
            return "(\(String(describing: node.stringRepresentation()))"
            
        case .invalidAST:
            return nil
        }
    }
    
    /// Returns the entire complex string resulting from collapsing this expression, on top of a given source string.
    /// Returns nil, if it's an invalid tree.
    func sourceString(onString source: String) -> String? {
        return sourceRange().flatMap { String(source[$0]) }
    }
}
