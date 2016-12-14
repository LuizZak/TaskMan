//
//  TimeCalcWindowController.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 13/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

class TimeCalcWindowController: NSWindowController {

    @IBOutlet var txtInput: NSTextView!
    @IBOutlet var txtOutput: NSTextView!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func textDidChange(_ notification: Notification) {
        evaluateOutput()
    }
    
    func evaluateOutput() {
        //outputTextView.string = inputTextView.string
        txtOutput.string = ""
        
        let lexer = Lexer(input: txtInput.string!)
        let parser = Parser(lexer: lexer)
        let typeResolver = TypeResolver()
        
        do {
            let expression = try parser.parse()
            
            switch(expression) {
            case .invalidAST(let error):
                txtOutput.string = "Error parsing expression: \(error)"
                return
            default:
                break
            }
            
            let typedExpression = try typeResolver.resolve(expression)
            
            if case .invalid(let message) = typedExpression.valueType() {
                txtOutput.string = "Error validating expression: \(message)"
                return
            }
            
            let evaluator = Evaluator()
            
            let result = evaluator.evaluate(typedExpression)
            
            txtOutput.string = "Result: \(result)"
            
            switch result {
            case .time(let time):
                txtOutput.string = (formatTime(time))
            case .string(let string):
                txtOutput.string = string
            default:
                break
            }
        } catch {
            txtOutput.string = "Error: \(error)"
        }
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        if(interval == 0) {
            return "00h00m"
        }
        
        let absInterval = abs(interval)
        
        let day: TimeInterval = 24 * 60 * 60
        let hour: TimeInterval = 60 * 60
        let minute: TimeInterval = 60
        
        var output = ""
        
        // Days
        if(absInterval >= day) {
            output += "\(String(format: "%02d", Int(floor(absInterval / day))))d"
        }
        // Hours
        if(absInterval >= hour && floor((absInterval.truncatingRemainder(dividingBy: day)) / hour) > 0) {
            output += "\(String(format: "%02d", Int(floor((absInterval.truncatingRemainder(dividingBy: day)) / hour))))h"
        }
        // Minutes
        if(absInterval >= minute && floor((absInterval.truncatingRemainder(dividingBy: hour)) / minute) > 0) {
            output += "\(String(format: "%02d", Int(floor((absInterval.truncatingRemainder(dividingBy: hour)) / minute))))m"
        }
        // Seconds
        if(floor(absInterval.truncatingRemainder(dividingBy: minute)) > 0) {
            output += "\(String(format: "%02d", Int(floor(absInterval.truncatingRemainder(dividingBy: minute)))))s"
        }
        // Milliseconds
        if(absInterval - floor(absInterval) > 0) {
            let milliseconds = floor(absInterval * 1000).truncatingRemainder(dividingBy: 1000)
            output += "\(String(format: "%02d", Int(milliseconds)))ms"
        }
        
        return interval < 0 ? "-\(output)" : output
    }
}
