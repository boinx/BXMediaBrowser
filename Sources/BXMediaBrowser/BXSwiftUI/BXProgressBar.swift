//**********************************************************************************************************************
//
//  BXProgressBar.swift
//	Displays a linear progress bar
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import SwiftUI
import AppKit


//----------------------------------------------------------------------------------------------------------------------


public struct BXProgressBar : NSViewRepresentable
{
	// Params
	
	var isIndeterminate:Bool = false
	var value:Double = 0.0
    var minValue:Double = 0.0
    var maxValue:Double = 1.0
	var size:NSControl.ControlSize = .regular
	
	// Init
	
	public init(isIndeterminate:Bool = false, value:Double = 0.0, minValue:Double = 0.0, maxValue:Double = 1.0, size:NSControl.ControlSize = .regular)
	{
		self.isIndeterminate = isIndeterminate
		self.value = value
		self.minValue = minValue
		self.maxValue = maxValue
		self.size = size
	}
	
	// Create the underlying AppKit view
	
	public func makeNSView(context:Context) -> NSProgressIndicator
    {
    	let progressBar = NSProgressIndicator(frame:.zero)
		progressBar.style = .bar
    	progressBar.controlSize = size
 		return progressBar
    }

	// SwiftUI side has changed, so update the AppKit view
	
	public func updateNSView(_ progressBar:NSProgressIndicator, context:Context)
    {
		progressBar.isIndeterminate = isIndeterminate
		progressBar.minValue = self.minValue
		progressBar.maxValue = self.maxValue
		progressBar.doubleValue = self.value
		
		if isIndeterminate
		{
			progressBar.usesThreadedAnimation = true
			progressBar.startAnimation(nil)
		}
		else
		{
			progressBar.usesThreadedAnimation = false
			progressBar.stopAnimation(nil)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
