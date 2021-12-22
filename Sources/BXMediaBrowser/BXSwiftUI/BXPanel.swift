//**********************************************************************************************************************
//
//  BXPanel.swift
//	An NSPanel subclass with SwiftUI content
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import AppKit
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public class BXPanel : NSPanel, NSWindowDelegate
{
	/// Store the number of BXPanels that are currently open
	
	private static var panelCount = 0

	/// Stores the topLeft corner position of the last BXPanel that was opened
	
	private static var topLeft:CGPoint = .zero
	
	
//----------------------------------------------------------------------------------------------------------------------


    /// Creates an NSPanel with the specified SwiftUI view as contents
    
    public init<V:View>(with view:V, title:String? = nil, shouldCascade:Bool = true)
    {
		// Create a hud panel window
	
 		super.init(
			contentRect:CGRect(x:0, y:0, width:300, height:200),
			styleMask:[.utilityWindow,.hudWindow,/*.nonactivatingPanel,*/.titled,.closable,.miniaturizable,.resizable],
			backing:.buffered,
			defer:false)

		self.delegate = self
		self.isMovableByWindowBackground = true

		Self.panelCount += 1

		// Set optional title
		
		if let title = title
		{
			self.title = title
		}
		
		// Install rootView
		
		let rootView = NSView(frame:.zero)
		self.contentView = rootView
		
		// Install SwiftUI content in a NSHostingView
		
		let hostingView = NSHostingView(rootView:view)
		rootView.addSubview(hostingView)
	
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		hostingView.topAnchor.constraint(equalTo:rootView.topAnchor).isActive = true
		hostingView.bottomAnchor.constraint(equalTo:rootView.bottomAnchor).isActive = true
		hostingView.leadingAnchor.constraint(equalTo:rootView.leadingAnchor).isActive = true
		hostingView.trailingAnchor.constraint(equalTo:rootView.trailingAnchor).isActive = true
		
		// Position window
		
		self.center()
		
		if shouldCascade
		{
			Self.topLeft = self.cascadeTopLeft(from:Self.topLeft)
		}
    }
	

//----------------------------------------------------------------------------------------------------------------------


	// After the last BXPanel is closed reset the window position to default (center)
	
	public func windowWillClose(_ notification: Notification)
    {
		Self.panelCount -= 1
		
		if Self.panelCount == 0
		{
			Self.topLeft = .zero
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------
