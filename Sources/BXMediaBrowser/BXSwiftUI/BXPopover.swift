//**********************************************************************************************************************
//
//  BXPopover.swift
//	An NSPopover subclass with SwiftUI content
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import Cocoa
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public class BXPopover : NSPopover, NSPopoverDelegate, ObservableObject
{
	/// Set this to true if you want the popover to automatically close, when the view it is attached to was scrolled out of sight. Please note that
	/// this will have no effect, if the popover is currently pinned. Since pinning has a higher priority, the popover will stay open in this case.
	
	public var autoClosesOnScrollingOutOfSight = true
	
	/// Set to true if the popover can be detached and moved around the screen
	
	public var allowDetaching = false
	
	/// Defines the visual appearance of the popover
	
	public var style:Style
	
	public enum Style
	{
		case system		// Default appearance (light or dark)
		case warning	// Yellow background and black text
		case error		// Red background and black text
	}
	
	/// Internal housekeeping
	
	private var observers:[Any] = []
	
	/// The popover is attached to this view
	
	private weak var parentView:NSView? = nil
	
	/// Sending this notification closes all BXPopover instances
	
	public static let closeAllNotification = NSNotification.Name("BXPopover.closeAll")
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates an NSPopover with the specified SwiftUI view as contents
    
    public init<V:View>(with view:V, style:Style = .system, colorScheme:ColorScheme = .dark)
    {
		self.style = style
        super.init()
        
        // Adapt text color to popover style
        
        var textColor = Color.primary
        var scheme = colorScheme
        
        if style == .warning
        {
			textColor = Color.black.opacity(0.9)
 			scheme = .light
       }
        else if style == .error
        {
			textColor = Color.black.opacity(0.9)
 			scheme = .light
        }
        
        let content = view
			.colorScheme(scheme)
			.foregroundColor(textColor)
			.environmentObject(self)
        
        // Create a view controller and embed the SwiftUI view
        
        let frame = CGRect(x:0, y:0, width:1000, height:1000) // For some reason this must be larger than zero initially or the content won't be visible at all
        let hostingView = NSHostingView(rootView:content)
		let rootView = NSView(frame:frame)
        rootView.addSubview(hostingView)

		hostingView.translatesAutoresizingMaskIntoConstraints = false
		hostingView.topAnchor.constraint(equalTo:rootView.topAnchor).isActive = true
		hostingView.bottomAnchor.constraint(equalTo:rootView.bottomAnchor).isActive = true
		hostingView.leadingAnchor.constraint(equalTo:rootView.leadingAnchor).isActive = true
		hostingView.trailingAnchor.constraint(equalTo:rootView.trailingAnchor).isActive = true
        
        let controller = NSViewController()
        controller.view = rootView
        self.contentViewController = controller
        
        self.delegate = self
        self.behavior = .transient
        self.animates = true

		NotificationCenter.default.addObserver(
            self,
            selector:#selector(close),
            name:Self.closeAllNotification,
            object:nil)
    }

    public required init?(coder:NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }


	// Apply special background color for warning and error popover styles. Technique was taken from:
	// https://stackoverflow.com/questions/19978620/how-to-change-nspopover-background-color-include-triangle-part
	
	public func popoverWillShow(_ notification:Notification)
	{
		guard self.style != .system else { return }
		guard let viewController = contentViewController else { return }
		guard let frameView = viewController.view.window?.contentView?.superview else { return }

		let backgroundColor = style == .warning ?
			CGColor(srgbRed:1, green:0.9, blue:0.6, alpha:1) :
			CGColor(srgbRed:1, green:0.6, blue:0.55, alpha:1)
			
		let backgroundView = NSView(frame: frameView.bounds)
		backgroundView.wantsLayer = true
		backgroundView.layer?.backgroundColor = backgroundColor
		backgroundView.autoresizingMask = [.width,.height]

		frameView.addSubview(backgroundView, positioned: .below, relativeTo: frameView)
	}


//----------------------------------------------------------------------------------------------------------------------


	public class func closeAll()
	{
		DispatchQueue.main.async
		{
			NotificationCenter.default.post(name:Self.closeAllNotification, object:nil)
		}
	}

    public func popoverWillClose(_ notification:Notification)
    {
		NotificationCenter.default.removeObserver(self)
	}
	
	deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
 
    
//----------------------------------------------------------------------------------------------------------------------
    
    
    /// Shows the popover in the specified parent view.
    
    public func show(relativeTo view:NSView)
    {
        let rect = NSInsetRect(view.bounds, 6.0, 6.0)
        self.show(relativeTo:rect, of:view, preferredEdge:NSRectEdge.maxY)
    }

    
	// When showing a popover in its parent view, then also listen to scrolling that might happen in the parent view.

    override public func show(relativeTo rect:NSRect, of view:NSView, preferredEdge:NSRectEdge)
    {
        super.show(relativeTo:rect, of:view, preferredEdge:preferredEdge)
		self.parentView = view
        
        if autoClosesOnScrollingOutOfSight, let scrollView = view.enclosingScrollView
        {
            NotificationCenter.default.addObserver(
                self,
                selector:#selector(didScrollAncestor),
                name:NSView.boundsDidChangeNotification,
                object:scrollView.contentView)
        }
	}
    
    
    // When a popover scrolls out of sight, then make sure it is automatically closed.
    
    @objc private func didScrollAncestor(_ notification:Notification)
    {
        guard let clipView = notification.object as? NSClipView else { return }
		guard let documentView = clipView.documentView else { return }
		guard self.isDetached == false else { return }
		
        let parentViewRect = documentView.convert(positioningRect, from:parentView)
        let visibleRect = clipView.documentVisibleRect
		
		if autoClosesOnScrollingOutOfSight && !NSIntersectsRect(parentViewRect,visibleRect)
        {
            self.performClose(self)
        }
    }
    
    
//----------------------------------------------------------------------------------------------------------------------
    
    
	/// Setting the owning window property has several effects. When the owning window is sent to the back,
	/// this popover will be hidden. When the owning window closes, then the popover will also close.
	
	public weak var owningWindow:NSWindow? = nil
	{
		didSet
		{
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(BXPopover._show),
				name: NSWindow.didBecomeMainNotification,
				object:owningWindow)

			NotificationCenter.default.addObserver(
				self,
				selector: #selector(BXPopover._hide),
				name: NSWindow.didResignMainNotification,
				object:owningWindow)

			NotificationCenter.default.addObserver(
				self,
				selector: #selector(performClose(_:)),
				name: NSWindow.willCloseNotification,
				object:owningWindow)
		}
	}
	
	
	@objc private func _show()
    {
		self.contentViewController?.view.window?.orderFront(nil)
    }
    
    @objc private func _hide()
    {
		self.contentViewController?.view.window?.orderOut(nil)
    }
	
	
//----------------------------------------------------------------------------------------------------------------------


    // Try to commit any changes in text fields - by resigning their firstResponder status. If that fails due to
    // validation errors, then do not allow closing the popover so that the error alert works without crashing.
    
    public func popoverShouldClose(_ popover:NSPopover) -> Bool
    {
		if let window = self.contentViewController?.view.window
        {
            return window.makeFirstResponder(nil)
        }
        
        return false
    }

    public func popoverShouldDetach(_ popover:NSPopover) -> Bool
    {
		return self.allowDetaching
    }


//----------------------------------------------------------------------------------------------------------------------


}
