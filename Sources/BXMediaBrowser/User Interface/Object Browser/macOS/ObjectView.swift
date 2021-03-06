//----------------------------------------------------------------------------------------------------------------------
//
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//----------------------------------------------------------------------------------------------------------------------


#if os(macOS)

import BXSwiftUtils
import AppKit


//----------------------------------------------------------------------------------------------------------------------


class ObjectView : NSView
{
	// MARK: - Hovering


	/// This externally supplied handler is called whenever the mouse enters or leaves this view
	
	public var mouseHoverHandler:((Bool)->Void)? = nil


	// Whenever the view frame changes, update the tracking area to detect mouse enter end exit events
	
	override func updateTrackingAreas()
	{
		super.updateTrackingAreas()
		
		self.trackingAreas.forEach { self.removeTrackingArea($0) }
		
		self.addTrackingArea(NSTrackingArea(
			rect: self.bounds,
			options: [.mouseEnteredAndExited,.activeInActiveApp,.assumeInside],
			owner: self,
			userInfo: nil))
	}
	
	// When the mouse enters, make this view visible
	
	override func mouseEntered(with event:NSEvent)
	{
		self.mouseHoverHandler?(true)
	}
	
	// When the mosue exits, hide this view again
	
	override func mouseExited(with event:NSEvent)
	{
		self.mouseHoverHandler?(false)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Context Menu
	
	typealias ContextMenuFactory = () -> NSMenu?
	
	/// This closure returns the context menu for a ObjectCell
	
	var contextMenuFactory:ContextMenuFactory? = nil
	
	/// Shows the context menu that was generated by the factory
	
	override func menu(for event:NSEvent) -> NSMenu?
	{
		self.contextMenuFactory?()
	}

}


//----------------------------------------------------------------------------------------------------------------------


#endif
