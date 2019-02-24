//
//  Lexer.swift
//  TimeCalc
//
//  Created by Luiz Fernando Silva on 19/10/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation

enum TokenType {
    case `operator`(operator: OperatorType)
    case float(float: Float)
    case time(time: TimeInterval)
    case string(string: String)
    case unknown
}

enum LexerError: Error {
    case invalidCharacter(message: String)
    case endOfStringError(message: String)
    case invalidDateValue(message: String)
    case unknownTokenType(message: String)
}

struct Token {
    var tokenType: TokenType
    var tokenString: String
    var inputRange: Range<String.Index>
}

enum OperatorType: String {
    case Addition = "+"
    case Subtraction = "-"
    case Multiplication = "*"
    case Division = "/"
    case OpenParenthesis = "("
    case CloseParenthesis = ")"
    case Format = ">"
}

class Lexer {
    static let timeLabels: [(label: String, seconds: TimeInterval)] = [("d", 60 * 60 * 24), ("h", 60 * 60), ("m", 60), ("s", 1), ("ms", 0.001)]
    
    private(set) var inputString: String {
        set {
            stateStack[stateStack.count - 1].inputString = newValue
        }
        get {
            return stateStack[stateStack.count - 1].inputString
        }
    }
    private(set) var offset: String.Index {
        set {
            stateStack[stateStack.count - 1].offset = newValue
        }
        get {
            return stateStack[stateStack.count - 1].offset
        }
    }
    
    private var stateStack: [LexerState] = []
    
    init(input: String) {
        stateStack.append(LexerState(inputString: input, offset: input.startIndex))
    }
    
    /// Pushes a new lexer state
    func pushState() {
        stateStack.append(stateStack[stateStack.count - 1])
    }
    
    /// Pops the top-most lexer state.
    /// Does not pop if the top-most state is the base state
    @discardableResult
    func popState() -> LexerState? {
        if stateStack.count > 1 {
            return stateStack.removeLast()
        }
        
        return nil
    }
    
    // MARK: Token checking/consuming
    
    /// Parses all the next tokens from the current offset to the end of the input string
    func readAllTokens() throws -> [Token] {
        var ret: [Token] = []
        
        skipWhitespace()
        
        while(!isEof()) {
            switch(nextTokenType()) {
            case .float, .time, .string:
                ret.append(try parseValue())
            case .operator:
                ret.append(try parseOperator().token)
            default:
                throw try unknownTokenTypeError("Unknown character token \(peek())")
            }
            
            skipWhitespace()
        }
        
        return ret
    }
    
    func nextTokenType() -> TokenType {
        // Skip whitespace temporarely
        pushState()
        defer {
            popState()
        }
        
        skipWhitespace()
        
        if(isNextTokenValue()) {
            if(isNextTokenTime()) {
                return .time(time: 0)
            }
            return .float(float: 0)
        }
        if isNextTokenOperator(), let type = try? operatorTypeForCharacter(peek()) {
            return .operator(operator: type)
        }
        if(isNextTokenString()) {
            return .string(string: "")
        }
        
        return .unknown
    }
    
    func isNextTokenOperator() -> Bool {
        // Skip whitespace temporarely
        pushState()
        defer {
            popState()
        }
        
        skipWhitespace()
        
        return !isEof() && isOperator(try! peek())
    }
    
    func isNextTokenOperator(_ op: OperatorType) -> Bool {
        // Skip whitespace temporarely
        pushState()
        defer {
            popState()
        }
        
        skipWhitespace()
        
        if(isEof() || !isOperator(try! peek())) {
            return false
        }
        
        if case .operator(op) = nextTokenType() {
            return true
        }
        
        return false
    }
    
    func isNextTokenValue() -> Bool {
        // Skip whitespace temporarely
        pushState()
        defer {
            popState()
        }
        
        skipWhitespace()
        
        return try! !isEof() && (isDigit(peek()) || isNextTokenString())
    }
    
    func isNextTokenInteger() -> Bool {
        // Skip whitespace temporarely
        pushState()
        defer {
            popState()
        }
        
        skipWhitespace()
        
        return !isEof() && isDigit(try! peek())
    }
    
    func isNextTokenTime() -> Bool {
        // Skip whitespace temporarely
        pushState()
        defer {
            popState()
        }
        
        skipWhitespace()
        
        if(isEof()) {
            return false
        }
        if(!isDigit(try! peek())) {
            return false
        }
        // Consume all digits
        if((try? parseIntString()) == nil) {
            return false
        }
        
        // Check if next token is ':' or a time label
        if(isEof()) {
            return false
        }
        let peekd = try! String(peek())
        if(peekd == ":" || Lexer.timeLabels.contains(where: { $0.label == peekd })) {
            return true
        }
        
        return false
    }
    
    func isNextTokenString() -> Bool {
        // Skip whitespace temporarely
        pushState()
        defer {
            popState()
        }
        
        skipWhitespace()
        
        return try! !isEof() && isStringDelimiter(peek())
    }
    
    func parseOperator() throws -> (token: Token, op: OperatorType) {
        skipWhitespace()
        
        if(!isOperator(try peek())) {
            throw invalidCharError("Expected operator but received '\(try peek())'")
        }
        
        let startOffset = offset
        
        let op = try operatorTypeForCharacter(peek())
        return (try Token(tokenType: .operator(operator: op), tokenString: String(next()), inputRange: startOffset..<offset), op)
    }
    
    func parseValue() throws -> Token {
        skipWhitespace()
        
        if(isNextTokenString()) {
            return try parseString()
        }
        
        let startOffset = offset
        
        var result = try parseFloatString()
        
        // Dot on number string - always float!
        if(result.contains(".")) {
            return Token(tokenType: .float(float: Float(result)!), tokenString: result, inputRange: startOffset..<offset)
        }
        
        let resultDouble = TimeInterval(result)!
        var pendingLabel = false
        
        if(try !isEof() && peek() == ":") {
            _ = try next() // Consume ":"
            
            let minutes = try parseIntString()
            
            let time = (TimeInterval(result)! * 60 * 60) + (TimeInterval(minutes)! * 60)
            
            // Read an hour label
            result += "h"
            result += minutes
            
            return Token(tokenType: .time(time: time), tokenString: result, inputRange: startOffset..<offset)
        }
        
        // No time label - integer value
        if(isEof() || !(try! isTimeLabel(peekIdent()))) {
            return Token(tokenType: .float(float: Float(resultDouble)), tokenString: result, inputRange: startOffset..<offset)
        }
        
        var timeTotal: TimeInterval = 0
        var lastValue = resultDouble
        
        var lastLabel = -1
        // Detect and read date labels
        while(try !isEof() && isTimeLabel(peekIdent()))
        {
            guard let labelIndex = try Lexer.timeLabels.index(where: { try $0.0 == peekIdent() }) else {
                break
            }
            
            timeTotal += lastValue * Lexer.timeLabels[labelIndex].seconds
            
            result += try nextIdent()
            
            if(lastLabel != -1 && labelIndex <= lastLabel)
            {
                throw invalidDateValueError("Invalidly formatted date value \(result)")
            }
            
            lastLabel = labelIndex
            
            pendingLabel = false
            
            // Read an integer value
            if(!isNextTokenInteger())
            {
                break
            }
            
            let nextInt = try parseIntString()
            lastValue = TimeInterval(nextInt)!
            result += nextInt
            
            // Invalid parsed date: cannot infer next date label type because it's smaller or equals to the previous
            if(labelIndex == Lexer.timeLabels.count - 1)
            {
                throw invalidDateValueError("Invalidly formatted date value \(result)")
            }
            
            pendingLabel = true
        }
        
        if(pendingLabel) {
            result += Lexer.timeLabels[lastLabel + 1].label
            timeTotal += lastValue * Lexer.timeLabels[lastLabel + 1].seconds
        }
        
        return Token(tokenType: .time(time: timeTotal), tokenString: result, inputRange: startOffset..<offset)
    }
    
    /// Parses a string token
    func parseString() throws -> Token {
        skipWhitespace()
        
        let startOffset = offset
        
        let delimiter = try peek()
        
        if(!isStringDelimiter(delimiter)) {
            throw try invalidCharError("Expected string delimiter \" or ' but received '\(peek())'")
        }
        
        _ = try next()
        var string = ""
        
        while(try !isEof() && peek() != delimiter) {
            try string.append(next())
        }
        
        // End delimiter
        if(try peek() != delimiter) {
            throw try invalidCharError("Expected end of string delimiter \(delimiter) but received '\(peek())'")
        }
        _ = try next() // Consume delimiter
        
        return Token(tokenType: .string(string: string), tokenString: "\(delimiter)\(string)\(delimiter)", inputRange: startOffset..<offset)
    }
    
    // MARK: String parsing methods
    func parseIntString() throws -> String {
        skipWhitespace()
        
        if(!isDigit(try peek())) {
            throw try invalidCharError("Expected integer but received '\(peek())'")
        }
        
        var result = ""
        
        while(try !isEof() && isDigit(peek()))
        {
            try result.append(next())
        }
        
        return result
    }
    
    func parseFloatString() throws -> String {
        skipWhitespace()
        
        // (0-9)+('.'(0..9)+)
        if(!isDigit(try peek())) {
            throw try invalidCharError("Expected float but received '\(peek())'")
        }
        
        var result = ""
        
        while(try !isEof() && isDigit(peek()))
        {
            try result.append(next())
        }
        
        if(try !isEof() && peek() == ".") {
            try result.append(next())
            
            // Expect more digits
            if(!isDigit(try peek())) {
                throw try invalidCharError("Expected float but received '\(peek())'")
            }
            
            while(try !isEof() && isDigit(peek()))
            {
                try result.append(next())
            }
        }
        
        return result
    }
    
    // MARK: String consuming methods
    func isEof() -> Bool {
        return offset >= inputString.endIndex
    }
    
    func peek() throws -> Character {
        if(isEof()) {
            throw endOfStringError()
        }
        
        return inputString[offset]
    }
    
    func peekIdent() throws -> String {
        pushState()
        defer {
            popState()
        }
        
        return try nextIdent()
    }
    
    func skipWhitespace() {
        while(!isEof() && isWhitespace(try! peek())) {
            _ = try! next()
        }
    }
    
    func next() throws -> Character {
        if(isEof()) {
            throw endOfStringError()
        }
        
        defer {
            offset = inputString.index(offset, offsetBy: 1)
        }
        
        return try peek()
    }
    
    func nextIdent() throws -> String {
        var buffer = ""
        
        if(isEof()) {
            throw endOfStringError()
        }
        
        while(try !isEof() && isLetter(peek())) {
            try buffer.append(next())
        }
        
        return buffer
    }
    
    // MARK: Character checking
    func isTimeLabel(_ st: String) -> Bool {
        return Lexer.timeLabels.contains(where: { $0.label == st })
    }
    
    func isOperator(_ c: Character) -> Bool {
        return c == "+" || c == "-" || c == "*" || c == "/" || c == "(" || c == ")" || c == ">"
    }
    
    func isDigit(_ c: Character) -> Bool {
        return c >= "0" && c <= "9"
    }
    
    func isStringDelimiter(_ c: Character) -> Bool {
        return c == "\"" || c == "\'"
    }
    
    func isWhitespace(_ c: Character) -> Bool {
        return CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(String(c).utf16.first!)!)
    }
    
    func isLetter(_ c: Character) -> Bool {
        return CharacterSet.letters.contains(UnicodeScalar(String(c).utf16.first!)!)
    }
    
    func operatorTypeForCharacter(_ c: Character) throws -> OperatorType {
        if let op = OperatorType(rawValue: String(c)) {
            return op
        }
        
        throw invalidCharError("Character \(c) does not resolve to any known operator")
    }
    
    // MARK: Error methods
    func invalidCharError(_ message: String) -> Error {
        return LexerError.invalidCharacter(message: message)
    }
    
    func invalidDateValueError(_ message: String) -> Error {
        return LexerError.invalidDateValue(message: message)
    }
    
    func endOfStringError(_ message: String = "Reached unexpected end of input string") -> Error {
        return LexerError.endOfStringError(message: message)
    }
    
    func unknownTokenTypeError(_ message: String) -> Error {
        return LexerError.unknownTokenType(message: message)
    }
    
    /// Represents the state of a lexer
    struct LexerState {
        var inputString: String
        var offset: String.Index
    }
}
