//
//  TimelineView.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 19/09/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import QuartzCore

let SegmentDragItemType = "taskman.segment"

/// Data source for a timeline view, which feeds task segments to the view
protocol TimelineViewDataSource: class {
    func segmentsForTimelineView(_ timelineView: TimelineView) -> [TaskSegment]
}

protocol TimelineViewDelegate: class {
    
    func backgroundColorForTimelineView(_ timelineView: TimelineView) -> NSColor
    
    func timelineView(_ timelineView: TimelineView, colorForSegment segment: TaskSegment) -> NSColor
    
    func timelineView(_ timelineView: TimelineView, taskForSegment segment: TaskSegment) -> Task
    
    func timelineView(_ timelineView: TimelineView, labelForSegment segment: TaskSegment) -> String
    
    func timelineView(_ timelineView: TimelineView, didTapSegment segment: TaskSegment, with event: NSEvent)
    
    func minimumStartDateForTimelineView(_ timelineView: TimelineView) -> Date?
    
    func minimumEndDateForTimelineView(_ timelineView: TimelineView) -> Date?
    
    /// Called to notify a segment is starting to be dragged on a timeline view.
    /// In case the delegate returns false, the drag event is aborted.
    /// Defaults to returning NO
    func timelineView(_ timelineView: TimelineView, willStartDraggingSegment segment: TaskSegment) -> Bool
}

extension TimelineViewDelegate {
    func timelineView(_ timelineView: TimelineView, didTapSegment segment: TaskSegment, with event: NSEvent) {
        
    }
    
    func minimumStartDateForTimelineView(_ timelineView: TimelineView) -> Date? {
        return nil
    }
    
    func minimumEndDateForTimelineView(_ timelineView: TimelineView) -> Date? {
        return nil
    }
    
    func timelineView(_ timelineView: TimelineView, willStartDraggingSegment segment: TaskSegment) -> Bool {
        return false
    }
}

class TimelineView: NSView {
    
    /// Segment currently under the user's mouse
    /// Is nil, is no segment
    fileprivate(set) var mouseSegment: TaskSegment?
    
    /// A simple user tag to tag the view with.
    /// Used to mostly figure out which specific task this timeline view is displaying.
    /// Defaults to -1
    var userTag: Int = -1
    
    /// Data source for fetching segments from
    weak var dataSource: TimelineViewDataSource? {
        didSet {
            mouseSegment = nil
            needsDisplay = true
        }
    }
    
    /// Delegate for presentation of this task timeline view
    weak var delegate: TimelineViewDelegate?
    
    /// Whether to display a tooltip when the user hovers over a task
    var showTooltip: Bool = true
    
    /// The date time formatter to use while formatting start/end display dates
    var dateTimeFormatter: DateFormatter = DateFormatter()
    
    /// Start presentation date for this timeline view
    var startDate: Date {
        guard let segments = dataSource?.segmentsForTimelineView(self) else {
            return Date()
        }
        
        let minDate = segments.earliestSegmentDate() ?? Date()
        
        if let minimumStartDate = self.delegate?.minimumStartDateForTimelineView(self) {
            return min(minimumStartDate, minDate)
        }
        return minDate
    }
    
    /// End presentation date for this timeline view
    var endDate: Date {
        guard let segments = dataSource?.segmentsForTimelineView(self) else {
            return Date()
        }
        
        let latest = segments.latestSegmentDate() ?? Date()
        
        if let minimumEndDate = self.delegate?.minimumEndDateForTimelineView(self) {
            return max(latest, minimumEndDate)
        }
        
        return latest
    }
    
    private(set) var lblStartTime = NSTextField()
    private(set) var lblEndTime = NSTextField()
    
    /// Dragging start point.
    /// Is nil, if the user is not pressing down on this timeline view yet
    fileprivate var dragStartPoint: NSPoint?
    /// Whether the user is currently in the process of dragging a segment
    fileprivate var dragging: Bool = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initView()
    }
    
    private func initView() {
        dateTimeFormatter.dateFormat = "HH:mm"
        
        // Add tracking
        let options: NSTrackingAreaOptions = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved]
        let area = NSTrackingArea(rect: bounds, options:options, owner: self, userInfo: nil)
        
        self.addTrackingArea(area)
        
        self.wantsLayer = true
        self.layer?.borderColor = NSColor.lightGray.cgColor
        self.layer?.borderWidth = 1
        self.layer?.masksToBounds = false
        
        // Configure labels
        configureLabel(label: lblStartTime)
        lblStartTime.alignment = .left
        lblStartTime.stringValue = "09:00"
        lblStartTime.sizeToFit()
        
        configureLabel(label: lblEndTime)
        lblEndTime.stringValue = "18:00"
        lblEndTime.alignment = .right
        lblEndTime.sizeToFit()
        
        addSubview(lblStartTime)
        addSubview(lblEndTime)
    }
    
    private func configureLabel(label: NSTextField) {
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.font = NSFont.labelFont(ofSize: 9)
        label.backgroundColor = NSColor.clear
        label.textColor = NSColor.white
        label.shadow = NSShadow()
        label.shadow?.shadowColor = NSColor.black
        label.shadow?.shadowBlurRadius = 2
    }
    
    override func layout() {
        lblStartTime.stringValue = dateTimeFormatter.string(from: startDate)
        lblStartTime.sizeToFit()
        lblStartTime.frame = lblStartTime.frame.insetBy(dx: -1, dy: -1)
        lblStartTime.frame.origin = NSPoint.zero
        
        lblEndTime.stringValue = dateTimeFormatter.string(from: endDate)
        lblEndTime.sizeToFit()
        lblEndTime.frame = lblEndTime.frame.insetBy(dx: -1, dy: -1)
        lblEndTime.frame.origin.y = 0
        lblEndTime.frame.origin.x = bounds.width - lblEndTime.frame.width
        
        super.layout()
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        guard let dragStartPoint = dragStartPoint, let mouseSegment = mouseSegment, let delegate = delegate else {
            return
        }
        
        let windowPoint = event.locationInWindow
        let point = self.convert(windowPoint, from: nil)
        
        // Dragging event
        if(!dragging) {
            // Detect move distance
            let distance = (dragStartPoint - point).magnitude
            
            // Ignore small drags
            if(distance <= 3 || !delegate.timelineView(self, willStartDraggingSegment: mouseSegment)) {
                return
            }
            
            dragging = true
            
            let paste = NSPasteboardItem()
            paste.setDataProvider(self, forTypes: [SegmentDragItemType, NSPasteboardTypeString])
            
            let item = NSDraggingItem(pasteboardWriter: paste)
            item.draggingFrame = frameFor(segment: mouseSegment)
            
            let image = NSDraggingImageComponent(key: "")
            image.contents = self.imageForSegment(segment: mouseSegment)
            image.frame = NSRect(origin: NSPoint.zero, size: item.draggingFrame.size)
            
            item.imageComponentsProvider = {
                return [image]
            }
            
            let session = beginDraggingSession(with: [item], event: event, source: self)
            
            session.animatesToStartingPositionsOnCancelOrFail = true
            session.draggingFormation = NSDraggingFormation.none
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        let windowPoint = event.locationInWindow
        let point = self.convert(windowPoint, from: nil)
        
        dragStartPoint = point
        
        let segment = segmentUnderPoint(point: point)
        
        let isLastSegment = mouseSegment?.id == segment?.id
        
        highlightSegment(segment: segment)
        
        if let segment = segment, !isLastSegment {
            addToolTip(frameFor(segment: segment), owner: self, userData: nil)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        dragStartPoint = nil
        
        let windowPoint = event.locationInWindow
        let point = self.convert(windowPoint, from: nil)
        
        if dragging == false, let segment = segmentUnderPoint(point: point) {
            delegate?.timelineView(self, didTapSegment: segment, with: event)
        }
        
        dragging = false
    }
    
    override func rightMouseUp(with event: NSEvent) {
        super.rightMouseUp(with: event)
        
        let windowPoint = event.locationInWindow
        let point = self.convert(windowPoint, from: nil)
        
        if let segment = segmentUnderPoint(point: point) {
            delegate?.timelineView(self, didTapSegment: segment, with: event)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        // De-select current segment
        highlightSegment(segment: nil)
    }
    
    override func view(_ view: NSView, stringForToolTip tag: NSToolTipTag, point: NSPoint, userData data: UnsafeMutableRawPointer?) -> String {
        if let mouseSegment = mouseSegment, let label = self.delegate?.timelineView(self, labelForSegment: mouseSegment) {
            return label
        }
        
        return ""
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
        lblStartTime.stringValue = dateTimeFormatter.string(from: startDate)
        lblEndTime.stringValue = dateTimeFormatter.string(from: endDate)
        
        let path = NSBezierPath()
        
        path.appendRect(bounds)
        
        (delegate?.backgroundColorForTimelineView(self) ?? NSColor.white).setFill()
        
        path.fill()
        
        guard let segments = dataSource?.segmentsForTimelineView(self) else {
            return
        }
        
        for segment in segments {
            // Draw each segment
            let frame = frameFor(segment: segment)
            
            // Ignore if not visible
            if(!dirtyRect.intersects(frame)) {
                continue
            }
            
            path.removeAllPoints()
            
            path.lineWidth = 2
            
            // Selected or not
            if(segment.id == self.mouseSegment?.id) {
                NSColor.black.setStroke()
                
                path.appendRect(frame.insetBy(dx: 0, dy: 1))
            } else {
                NSColor.clear.setStroke()
                
                path.appendRect(frame)
            }
            
            (delegate?.timelineView(self, colorForSegment: segment) ?? NSColor.blue)?.setFill()
            
            path.stroke()
            path.fill()
        }
    }
    
    func imageForSegment(segment: TaskSegment) -> NSImage? {
        let frame = frameFor(segment: segment)
        
        if(frame.width > 4096 || frame.height > 4096) {
            return nil
        }
        
        let image = NSImage(size: frame.size)
        
        image.lockFocus()
        
        let path = NSBezierPath()
        
        path.lineWidth = 2
        
        NSColor.clear.setStroke()
        
        path.appendRect(NSRect(origin: NSPoint.zero, size: frame.size))
        
        (delegate?.timelineView(self, colorForSegment: segment) ?? NSColor.blue)?.setFill()
        
        path.stroke()
        path.fill()
        
        image.unlockFocus()
        
        return image
    }
    
    // MARK: - Highlighting Management
    
    func highlightSegment(segment: TaskSegment?) {
        if let previous = mouseSegment {
            let frame = frameFor(segment: previous)
            setNeedsDisplay(frame.insetBy(dx: -2, dy: -2))
        }
        
        mouseSegment = segment
        
        if let new = segment {
            let frame = frameFor(segment: new)
            setNeedsDisplay(frame.insetBy(dx: -2, dy: -2))
        }
    }
    
    // MARK: - Positioning
    func segmentUnderPoint(point: NSPoint) -> TaskSegment? {
        // Reverse so search finds the top-most segment always
        guard let segments = dataSource?.segmentsForTimelineView(self).reversed() else {
            return nil
        }
        
        for segment in segments {
            if(frameFor(segment: segment).contains(point)) {
                return segment
            }
        }
        
        return nil
    }
    
    func boundsForSegments() -> NSRect {
        return NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
    }
    
    func frameFor(segment: TaskSegment) -> NSRect {
        let interval = endDate.timeIntervalSince(startDate)
        let start = segment.range.startDate.timeIntervalSince(startDate)
        let end = segment.range.endDate.timeIntervalSince(startDate)
        
        let startX = (start / interval) * Double(boundsForSegments().width)
        let endX = (end / interval) * Double(boundsForSegments().width)
        
        return NSRect(x: startX + Double(boundsForSegments().origin.x),
                      y: Double(boundsForSegments().origin.y),
                      width: endX - startX,
                      height: Double(boundsForSegments().height))
    }
}

extension TimelineView : NSPasteboardItemDataProvider {
    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: String) {
        if(type == SegmentDragItemType || type == NSPasteboardTypeString) {
            if let mouseSegment = mouseSegment {
                item.setString(mouseSegment.serialize().rawString(), forType: type)
            }
        }
    }
}

extension TimelineView : NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        switch(context) {
        case .withinApplication:
            return NSDragOperation.move
            
        case .outsideApplication:
            return NSDragOperation.copy
        }
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        mouseSegment = nil
        dragStartPoint = nil
        dragging = false
    }
}
