//
//  Parser.swift
//  TimeCalc
//
//  Created by Luiz Fernando Silva on 28/10/15.
//  Copyright © 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation

class Parser {
    var lexer: Lexer
    
    init(lexer: Lexer) {
        self.lexer = lexer
    }
    
    // Parses a tree from the lexer
    func parse() throws -> ASTreeNode {
        let exp = try expression()
        
        // Check if it's not EoF
        lexer.skipWhitespace()
        if(!lexer.isEof()) {
            return ASTreeNode.invalidAST(error: "Expected EoF at \(lexer.offset), received \(lexer.nextTokenType())")
        }
        
        return orderOperatorsRecursive(exp)
    }
    
    // Parses an expression tree
    //
    // expr:
    //      value binary-expr*
    //      parenthesis-expr binary-expr*
    //
    // binary-expr:
    //      operator value
    //      operator parenthesis-expr
    //
    // parenthesis-expr:
    //      '(' expr ')'
    //
    func expression() throws -> ASTreeNode {
        
        // Always start by reading a value
        if(!lexer.isNextTokenValue()) {
            if(!lexer.isNextTokenOperator(.OpenParenthesis)) {
                return ASTreeNode.invalidAST(error: "Expected value at index \(lexer.offset), received \(lexer.nextTokenType())")
            }
        }
        
        var val: ASTreeNode
        
        // Parenthesized expression
        if lexer.isNextTokenOperator(.OpenParenthesis) {
            val = try parensExpression()
        } else {
            // Start by reading a value
            val = try value()
        }
        
        while(true) {
            // End of parenthesized expression
            guard lexer.isNextTokenOperator() && !lexer.isNextTokenOperator(.CloseParenthesis) else {
                break
            }
            
            // Read one expression
            let op = try lexer.parseOperator()
            let rhs: ASTreeNode
            
            if(lexer.isNextTokenOperator(.OpenParenthesis)) {
                // Consume open and close parenthesis and collect the inner expression
                rhs = try parensExpression()
            } else {
                rhs = try value()
            }
            
            if case .invalidAST = rhs {
                return rhs
            }
            
            val = .binaryExpression(leftValue: val, operator: op.op, rightValue: rhs)
        }
        
        return val
    }
    
    // Parses a parenthesized expression
    //
    // parenthesis-expr:
    //      '(' expr ')'
    //
    func parensExpression() throws -> ASTreeNode {
        if(!lexer.isNextTokenOperator(.OpenParenthesis)) {
            return ASTreeNode.invalidAST(error: "Expected open parens '(' at index \(self.lexer.offset), received \(self.lexer.nextTokenType())")
        }
        
        _ = try lexer.parseOperator()
        
        let exp = try expression()
        
        if(!lexer.isNextTokenOperator(.CloseParenthesis)) {
            return ASTreeNode.invalidAST(error: "Expected closing parens ')' at index \(self.lexer.offset), received \(self.lexer.nextTokenType())")
        }
        
        _ = try lexer.parseOperator()
        
        // Collapse parenthesized expressions so they don't recurse up unnecessarily
        if case .parenthesizedExpression(_) = exp {
            return exp
        }
        
        return ASTreeNode.parenthesizedExpression(expression: exp)
    }
    
    // Parses a value from the lexer
    //
    // value:
    //      float
    //      time-rep
    //      string
    //
    // float:
    //      [0-9]+(.[0-9]+)?
    func value() throws -> ASTreeNode {
        do {
            // Temporarely push a state to try to parse the values from
            defer {
                lexer.popState()
            }
            lexer.pushState()
            
            _ = try lexer.parseValue()
        }
        
        let value = try lexer.parseValue()
        return .value(value: ASTreeValue(rawString: value.tokenString, type: .unknown, source: value))
    }
    
    /// Balances the given binary expression tree so that the order of operands is respected
    func orderOperatorsRecursive(_ expression: ASTreeNode) -> ASTreeNode {
        var expression = expression
        // Balance recursively beforehands
        switch(expression) {
        case .unaryExpression(let op, let value):
            return .unaryExpression(operator: op, value: value)
            
            
        case .parenthesizedExpression(let exp):
            return .parenthesizedExpression(expression: orderOperatorsRecursive(exp))
            
        // Binary expression is balanced bellow
        case .binaryExpression(let left, let op, let right):
            expression = .binaryExpression(leftValue: orderOperatorsRecursive(left), operator: op, rightValue: orderOperatorsRecursive(right))
            
        // Unrecognized expression cannot be balanced
        default:
            return expression
        }
        
        // Balance binary expression
        
        // Case 3: Two subtrees
        if case .binaryExpression(.binaryExpression(_, let lOp, _),
                                  let op,
                                  .binaryExpression(_, let rOp, _)) = expression {
            
            // Operators already in order - skip
            if(operandWeight(op) <= operandWeight(lOp) && operandWeight(op) <= operandWeight(rOp)) {
                return expression
            }
            
            // Operator on left is higher precedence - on right is not
            if(operandWeight(op) > operandWeight(lOp) && operandWeight(op) <= operandWeight(rOp)) {
                return orderOperatorsRecursive(expression.rotateRight())
            }
            
            // Operator on right is higher precedence - on left is not
            if(operandWeight(op) <= operandWeight(lOp) && operandWeight(op) > operandWeight(rOp)) {
                return orderOperatorsRecursive(expression.rotateRight())
            }
            
            // Both operators are same precedence - either rotation will result in a more balanced tree
            return orderOperatorsRecursive(expression.rotateRight())
        }
        
        // Case 1: Left subrtee only
        if case .binaryExpression(.binaryExpression(_, let lOp, _),
                                  let op,
                                  _) = expression {
            
            if(operandWeight(op) > operandWeight(lOp)) {
                return orderOperatorsRecursive(expression.rotateRight())
            }
        }
        
        // Case 2: Right subtree only
        if case .binaryExpression(_,
                                  let op,
                                  .binaryExpression(_, let rOp, _)) = expression {
            
            if(operandWeight(op) > operandWeight(rOp)) {
                return orderOperatorsRecursive(expression.rotateLeft())
            }
        }
        
        return expression
    }
    
    func operandWeight(_ operand: OperatorType) -> Int {
        switch(operand) {
        case .Addition, .Subtraction:
            return 1
        case .Multiplication, .Division:
            return 2
            
        default:
            return 0
        }
    }
}
