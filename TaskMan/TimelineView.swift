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
    
    func timelineView(_ timelineView: TimelineView, labelForSegment segment: TaskSegment) -> String
    
    func timelineView(_ timelineView: TimelineView, didTapSegment segment: TaskSegment, with event: NSEvent)
    
    /// Called when the user has tapped a portion of the timeline view with no segments on
    func timelineView(_ timelineView: TimelineView, didTapEmptyDate date: Date, with event: NSEvent)
    
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
    
    func timelineView(_ timelineView: TimelineView, didTapEmptyDate date: Date, with event: NSEvent) {
        
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
    /// Is nil, if no segment is under the mouse currently.
    fileprivate(set) var mouseSegment: TaskSegment?
    
    /// Date the mouse is currently pointing at on this timeline view.
    /// Is nil, if the mouse is not within the bounds of this timeline view.
    fileprivate(set) var mouseDate: Date? {
        didSet {
            if(oldValue != mouseDate) {
                needsDisplay = true
            }
        }
    }
    
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
    
    /// Whether to draw the current time on the timeline, as a red/white vertical bar
    var drawCurrentTime: Bool = true
    
    /// Whether to display a tooltip when the user hovers over a task
    var showTooltip: Bool = true
    
    /// The date time formatter to use while formatting start/end display dates
    var dateTimeFormatter: DateFormatter = DateFormatter()
    
    /// The calendar to use when performing date calculations
    var calendar: Calendar = Calendar.autoupdatingCurrent
    
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
    
    
    /// Current zoom level.
    /// Must be between 1 and 5
    var zoomLevel: CGFloat = 1 {
        didSet {
            if(zoomLevel < 1) {
                zoomLevel = 1
            }
            if(zoomLevel > 10) {
                zoomLevel = 10
            }
            
            needsLayout = true
            needsDisplay = true
        }
    }
    
    /// Offset of the contents of this view. This offsets the timeline contents and labels
    /// by the set ammount.
    /// y axis is ignored, x axis is locked to be > 0 && < bounds.width
    var contentOffset: NSPoint = NSPoint.zero {
        didSet {
            if(contentOffset.x > 0) {
                contentOffset.x = 0
            }
            let segBounds = boundsForSegments()
            if(contentOffset.x < -(segBounds.width - bounds.width)) {
                contentOffset.x = -(segBounds.width - bounds.width)
            }
            
            needsLayout = true
            needsDisplay = true
        }
    }
    
    /// Point at which the zoom started being performed.
    /// Represented as a value between 0-1, with 0 being the start
    /// date, and 1 the end date of this view's date range.
    fileprivate var zoomStartLocation: CGFloat = 0
    /// Used to trap scrolling wheel after the user has started scrolling horizontally
    /// even if the user starts moving vertically.
    /// This allows smooth use even inside scroll views
    fileprivate var scrollLocked = false
    
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
        label.textColor = NSColor.black
        label.shadow = NSShadow()
        label.shadow?.shadowColor = NSColor.white
        label.shadow?.shadowBlurRadius = 2
    }
    
    override func layout() {
        let bounds = boundsForSegments()
        
        lblStartTime.stringValue = dateTimeFormatter.string(from: startDate)
        lblStartTime.sizeToFit()
        lblStartTime.frame = lblStartTime.frame.insetBy(dx: -1, dy: -1)
        lblStartTime.frame.origin.y = 0
        lblStartTime.frame.origin.x = bounds.origin.x
        
        lblEndTime.stringValue = dateTimeFormatter.string(from: endDate)
        lblEndTime.sizeToFit()
        lblEndTime.frame = lblEndTime.frame.insetBy(dx: -1, dy: -1)
        lblEndTime.frame.origin.y = 0
        lblEndTime.frame.origin.x = bounds.origin.x + bounds.width - lblEndTime.frame.width
        
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
        
        updateMouseDisplay(withEvent: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        dragStartPoint = nil
        
        let windowPoint = event.locationInWindow
        let point = self.convert(windowPoint, from: nil)
        
        if dragging == false, let segment = segmentUnder(point: point) {
            delegate?.timelineView(self, didTapSegment: segment, with: event)
        } else if(dragging == false) {
            if(self.bounds.contains(point)) {
                delegate?.timelineView(self, didTapEmptyDate: dateForOffset(at: point.x), with: event)
            }
        }
        
        dragging = false
    }
    
    override func rightMouseUp(with event: NSEvent) {
        super.rightMouseUp(with: event)
        
        let windowPoint = event.locationInWindow
        let point = self.convert(windowPoint, from: nil)
        
        if let segment = segmentUnder(point: point) {
            delegate?.timelineView(self, didTapSegment: segment, with: event)
        } else {
            if(self.bounds.contains(point)) {
                delegate?.timelineView(self, didTapEmptyDate: dateForOffset(at: point.x), with: event)
            }
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        
        updateMouseDisplay(withEvent: event)
        
        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        // De-select current segment
        mouseDate = nil
        highlightSegment(segment: nil)
        
        needsDisplay = true
    }
    
    
    override func magnify(with event: NSEvent) {
        super.magnify(with: event)
        
        let windowPoint = event.locationInWindow
        let point = self.convert(windowPoint, from: nil)
        
        let segmentBounds = boundsForSegments()
        
        // Change offset depending on location of touch before/after magnification
        switch(event.phase) {
        case NSEventPhase.began:
            let absoluteX = point.x - segmentBounds.minX
            
            zoomStartLocation = absoluteX / segmentBounds.width
        case NSEventPhase.changed:
            zoomLevel += event.magnification
            
            let afterBounds = boundsForSegments()
            let absoluteX = point.x - afterBounds.minX
            contentOffset.x += absoluteX - (afterBounds.width * zoomStartLocation)
        default:
            break
        }
        
        updateMouseDisplay(withEvent: event)
    }
    
    override func scrollWheel(with event: NSEvent) {
        // Vertical scroll - ignore
        if(!scrollLocked && abs(event.scrollingDeltaX) < abs(event.scrollingDeltaY)) {
            super.scrollWheel(with: event)
            return
        }
        // Lock scroll so we don't ignore vertical scrolls after the user has started scrolling this timeline view
        scrollLocked = true
        if(event.phase == .changed) {
            contentOffset.x += event.scrollingDeltaX
        } else if(event.phase == .ended || event.phase == .cancelled) {
            scrollLocked = false
        }
        
        updateMouseDisplay(withEvent: event)
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
        
        let boundsForSegs = boundsForSegments()
        let start = startDate
        let end = endDate
        
        guard let context = NSGraphicsContext.current() else {
            return
        }
        
        // Draw hour bars
        renderHourBars(context: context, startDate: start, endDate: end, clipRect: dirtyRect, segmentBounds: boundsForSegs)
        
        NSColor.clear.setStroke()
        
        for segment in segments {
            // Draw each segment
            let frame = frameFor(segment: segment, withStartDate: start, endDate: end, inBounds: boundsForSegs)
            
            // Ignore if not visible
            if(!dirtyRect.intersects(frame)) {
                continue
            }
            
            path.removeAllPoints()
            
            path.lineWidth = 1
            
            path.appendRect(frame)
            
            let color = (delegate?.timelineView(self, colorForSegment: segment) ?? NSColor.blue)
            color.setFill()
            
            path.fill()
            
            // Stroke
            path.removeAllPoints()
            path.appendRect(frame.insetBy(dx: min(frame.width / 2, 0.5), dy: 0))
            
            color.shadow(withLevel: 0.3)?.withAlphaComponent(color.alphaComponent).setStroke()
            path.stroke()
        }
        
        // Draw selected mouse segment
        if let mouseSeg = segments.first(where: { $0.id == mouseSegment?.id }) {
            let frame = frameFor(segment: mouseSeg, withStartDate: start, endDate: end, inBounds: boundsForSegs)
            
            if(dirtyRect.intersects(frame)) {
                path.removeAllPoints()
                
                NSColor.black.setStroke()
                path.lineWidth = 2
                path.appendRect(frame.insetBy(dx: min(frame.width / 2, 1), dy: min(frame.height / 2, 1)))
                path.stroke()
            }
        } else if let mouseDate = mouseDate, let range = emptyRangeUnderDate(date: mouseDate), range.timeInterval > 0 {
            // Draw empty space, if mouse is over one
            let frame = frameForDateRange(dateRange: range, withStartDate: start, endDate: end, inBounds: boundsForSegs)
            
            if(dirtyRect.intersects(frame)) {
                path.removeAllPoints()
                
                NSColor.selectedControlColor.highlight(withLevel: 0.3)?.setStroke()
                path.lineWidth = 2
                path.appendRect(frame.insetBy(dx: min(frame.width / 2, 1), dy: min(frame.height / 2, 1)))
                path.stroke()
            }
        }
        
        // Draw current time
        if(drawCurrentTime) {
            renderTimeIndicator(context: context, onDate: Date(), clipRect: dirtyRect)
        }
    }
    
    /// Updates currently hovered over segment and empty dates based on the given event
    func updateMouseDisplay(withEvent event: NSEvent) {
        let windowPoint = event.locationInWindow
        let point = self.convert(windowPoint, from: nil)
        
        if(boundsForSegments().contains(point)) {
            mouseDate = dateForOffset(at: point.x)
        } else {
            mouseDate = nil
        }
        
        dragStartPoint = point
        
        let segment = segmentUnder(point: point)
        
        let isLastSegment = mouseSegment?.id == segment?.id
        if(!isLastSegment && (mouseSegment == nil || segment == nil)) {
            needsDisplay = true
        }
        
        highlightSegment(segment: segment)
        
        if let segment = segment, !isLastSegment {
            addToolTip(frameFor(segment: segment), owner: self, userData: nil)
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
            setNeedsDisplay(frame)
        }
        
        mouseSegment = segment
        
        if let new = segment {
            let frame = frameFor(segment: new)
            setNeedsDisplay(frame)
        }
    }
    
    // MARK: - Positioning
    func segmentUnder(point: NSPoint) -> TaskSegment? {
        // Reverse so search finds the top-most segment always
        guard let segments = dataSource?.segmentsForTimelineView(self).reversed() else {
            return nil
        }
        // Ignore, if out of bounds
        if(!boundsForSegments().contains(point)) {
            return nil
        }
        
        let date = dateForOffset(at: point.x)
        
        for segment in segments {
            if(segment.range.contains(date: date)) {
                return segment
            }
        }
        
        return nil
    }
    
    /// Returns a date range that fills the empty space on top of the given date, if any.
    /// If the date is out of the bounds for this timeline view, nil is returned.
    /// If the date points within a segment, nil is also returned.
    /// If not, the method returns the biggest date range capable of filling the space
    /// under the date, stopping at segments and the boundaries of this timeline view.
    func emptyRangeUnderDate(date: Date) -> DateRange? {
        guard let segments = dataSource?.segmentsForTimelineView(self) else {
            return nil
        }
        
        let sDate = startDate
        let eDate = endDate
        
        if(date < sDate || date > eDate) {
            return nil
        }
        
        if(segments.any { $0.range.contains(date: date) }) {
            return nil
        }
        
        let start = segments.filter { $0.range.endDate < date }.latestSegmentDate() ?? sDate
        let end = segments.filter { $0.range.startDate > date }.earliestSegmentDate() ?? eDate
        
        return DateRange(startDate: start, endDate: end)
    }
    
    fileprivate func renderTimeIndicator(context: NSGraphicsContext, onDate date: Date, clipRect: NSRect) {
        let cgContext = context.cgContext
        let offset = offsetFor(date: date)
        
        // Time is not within the dirty region to redraw
        if(!clipRect.contains(CGPoint(x: offset, y: clipRect.midY))) {
            return
        }
        
        // Add stripped red line
        cgContext.addLines(between: [NSPoint(x: offset, y: bounds.minY), NSPoint(x: offset, y: bounds.maxY)])
        
        let t: CGFloat = CGFloat(CACurrentMediaTime().truncatingRemainder(dividingBy: 8))
        
        NSColor.red.setStroke()
        cgContext.setLineDash(phase: t, lengths: [4, 4])
        cgContext.strokePath()
        
        // Add stripped white line
        cgContext.addLines(between: [NSPoint(x: offset, y: bounds.minY), NSPoint(x: offset, y: bounds.maxY)])
        NSColor.white.setStroke()
        cgContext.setLineDash(phase: 4 + t, lengths: [4, 4])
        cgContext.strokePath()
        
        var ellipseRect = CGRect(x: offset, y: bounds.minY + 1, width: 4, height: 4)
        ellipseRect = ellipseRect.offsetBy(dx: -ellipseRect.width / 2, dy: -ellipseRect.height / 2)
        
        cgContext.setLineDash(phase: 0, lengths: [])
        NSColor.white.setStroke()
        
        // Top ellipse
        NSColor.red.setFill()
        cgContext.addEllipse(in: ellipseRect)
        cgContext.drawPath(using: CGPathDrawingMode.fillStroke)
        
        // Bottom ellipse
        NSColor.red.setFill()
        cgContext.addEllipse(in: ellipseRect.offsetBy(dx: 0, dy: bounds.height - 2))
        cgContext.drawPath(using: CGPathDrawingMode.fillStroke)
    }
    
    
    fileprivate func renderHourBars(context: NSGraphicsContext, startDate: Date, endDate: Date, clipRect: NSRect, segmentBounds: NSRect) {
        if(!clipRect.intersects(segmentBounds)) {
            return
        }
        
        let totalTime = endDate.timeIntervalSince(startDate)
        
        // Avoid drawing too many vertical lines (> 100)
        if(totalTime > 100 * 3600) {
            return
        }
        
        // Find how wide an hour is on the timeline view
        // tw: Total width
        // ts: Total time (in seconds)
        // hw: Hour width (equation's X)
        //
        //  tw     hw
        // ---- = ----
        //  ts    3600
        
        // hw.ts = 3600tw
        
        //       3600tw
        // hw =  ------
        //         ts
        
        let hourSecs = 3600
        let hourWidth = CGFloat(hourSecs) * segmentBounds.width / CGFloat(totalTime)
        
        // Obtain rounded-down hour for offset, and start travelling to the right
        let components = calendar.dateComponents([.calendar, .era, .year, .month, .weekday, .day, .hour], from: startDate)
        let date = calendar.date(from: components) ?? startDate
        
        // Start from the left-most date, and scroll every hour drawing a vertical gray bar
        var x = segmentBounds.minX - (CGFloat(startDate.timeIntervalSince(date)) / CGFloat(hourSecs)) * hourWidth
        let y = bounds.height
        let h = -bounds.height
        var hoursAdded = 0
        
        let path = NSBezierPath()
        
        NSColor(white: 0.9, alpha: 1).setStroke()
        
        while x < segmentBounds.maxX {
            x += hourWidth
            hoursAdded += 1
            
            if(clipRect.minX >= x || segmentBounds.minX >= x) {
                continue
            }
            if(clipRect.maxX <= x) {
                break
            }
            
            // Verify we are not at a 0h, if we are, draw a solid vertical bar instead of a dashed one
            let curDate = calendar.date(byAdding: .hour, value: hoursAdded, to: date)!
            if(calendar.component(.hour, from: curDate) == 0) {
                path.setLineDash([], count: 0, phase: 0)
            } else {
                path.setLineDash([5, 4], count: 2, phase: 0)
            }
            
            path.removeAllPoints()
            path.move(to: NSPoint(x: x, y: y))
            path.line(to: NSPoint(x: x, y: y + h))
            path.stroke()
        }
    }
}

// MARK: Sizings
extension TimelineView {
    func boundsForSegments() -> NSRect {
        let offY: CGFloat = 14
        
        return NSRect(origin: contentOffset + NSPoint(x: 0, y: offY), size: NSSize(width: boundWidth(), height: bounds.height - offY))
    }
    
    func boundWidth() -> CGFloat {
        return bounds.width * zoomLevel
    }
    
    func frameFor(segment: TaskSegment) -> NSRect {
        return frameFor(segment: segment, withStartDate: startDate, endDate: endDate, inBounds: boundsForSegments())
    }
    
    func frameFor(segment: TaskSegment, withStartDate startDate: Date, endDate: Date, inBounds bounds: NSRect) -> NSRect {
        return frameForDateRange(dateRange: segment.range, withStartDate: startDate, endDate: endDate, inBounds: bounds)
    }
    
    func frameForDateRange(dateRange: DateRange, withStartDate startDate: Date, endDate: Date, inBounds bounds: NSRect) -> NSRect {
        let interval = endDate.timeIntervalSince(startDate)
        let start = dateRange.startDate.timeIntervalSince(startDate)
        let end = dateRange.endDate.timeIntervalSince(startDate)
        
        let startX = CGFloat(start / interval) * bounds.width
        let endX = CGFloat(end / interval) * bounds.width
        
        let frame = NSRect(x: startX + bounds.origin.x,
                           y: bounds.origin.y,
                           width: endX - startX,
                           height: bounds.height)
        
        return self.bounds.intersection(frame) // Clip rect to be within this view's visible bounding frame
    }
    
    func offsetFor(date: Date) -> CGFloat {
        let sDate = startDate
        let timelineInterval = endDate.timeIntervalSince(sDate)
        let dateOffset = date.timeIntervalSince(sDate)
        
        return contentOffset.x + CGFloat(dateOffset / timelineInterval) * boundWidth()
    }
    
    func dateForOffset(at point: CGFloat) -> Date {
        let off = point - contentOffset.x
        let ratio = off / boundWidth()
        
        let sDate = startDate
        let timeInterval = endDate.timeIntervalSince(sDate)
        
        return sDate.addingTimeInterval(TimeInterval(ratio) * timeInterval)
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
