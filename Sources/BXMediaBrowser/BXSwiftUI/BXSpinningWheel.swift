//**********************************************************************************************************************
//
//  BXSpinningWheel.swift
//	Displays a circular spinning wheel
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import SwiftUI
import AppKit


//----------------------------------------------------------------------------------------------------------------------


public struct BXSpinningWheel : NSViewRepresentable
{
	// Params
	
	var size:NSControl.ControlSize = .regular
	
	// Init
	
	public init(size:NSControl.ControlSize = .regular)
	{
		self.size = size
	}
	
	// Create the underlying AppKit view
	
	public func makeNSView(context:Context) -> NSProgressIndicator
    {
    	let wheel = NSProgressIndicator(frame:.zero)
		wheel.style = .spinning
    	wheel.controlSize = self.size
    	wheel.isIndeterminate = true
		wheel.usesThreadedAnimation = true
		wheel.isDisplayedWhenStopped = false
    	wheel.startAnimation(nil)
 		return wheel
    }

	// SwiftUI side has changed, so update the AppKit view
	
	public func updateNSView(_ wheel:NSProgressIndicator, context:Context)
    {

	}
}


//----------------------------------------------------------------------------------------------------------------------
