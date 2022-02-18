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

import AppKit
import SwiftUI
import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


class ObjectRatingView : NSView
{
	public var rating:Binding<Int> = Binding<Int>.constant(0)
	
	public var size:CGFloat = 16
	
	
//----------------------------------------------------------------------------------------------------------------------


//	public override init(frame:NSRect)
//	{
//		super.init(frame:frame)
//	}
//	
//	
//	required init?(coder:NSCoder)
//	{
//		super.init(coder:coder)
//	}
	
	
//----------------------------------------------------------------------------------------------------------------------


//	// Whenever the view frame changes, update the tracking area to detect mouse enter end exit events
//
//	override func updateTrackingAreas()
//	{
//		super.updateTrackingAreas()
//
//		self.trackingAreas.forEach { self.removeTrackingArea($0) }
//
//		self.addTrackingArea(NSTrackingArea(
//			rect: self.bounds,
//			options: [.mouseEnteredAndExited,.activeInActiveApp,.assumeInside],
//			owner: self,
//			userInfo: nil))
//	}
//
//	// When the mouse enters, make this view visible
//
//	override func mouseEntered(with event:NSEvent)
//	{
//		self.isVisible = true
//	}
//
//	// When the mosue exits, hide this view again
//
//	override func mouseExited(with event:NSEvent)
//	{
//		self.isVisible = false
//	}
//
//	/// Sets the view visibility - i.e. unless the rating is larger than 0 -
//	/// in that case it the view will always be visible!
//
//	var isVisible:Bool
//	{
//		set
//		{
//			let rating = self.rating.wrappedValue
//
//			if newValue || rating > 0
//			{
//				self.alphaValue = 1.0
//			}
//			else
//			{
//				self.alphaValue = 0.0
//			}
//		}
//
//		get
//		{
//			self.alphaValue > 0.0
//		}
//	}
	

//----------------------------------------------------------------------------------------------------------------------


	override func draw(_ rect:NSRect)
	{
		if #available(macOS 11, *)
		{
			let off = NSImage(systemSymbolName:"star", accessibilityDescription:nil)
//			off?.tint = NSColor.controlColor
			off?.isTemplate = true
			
			let on = NSImage(systemSymbolName:"star.fill", accessibilityDescription:nil)
//			on?.tint = NSColor.systemYellow
			on?.isTemplate = true
			
			let rating = self.rating.wrappedValue
			var frame = CGRect(x:0, y:0, width:size, height:size)
			
			for i in 1...5
			{
				frame.origin.x = CGFloat(i-1) * size
				frame.origin.y = bounds.maxY - size

				let image = i <= rating ? on : off
				image?.draw(in:frame)
			}
		}
	}
	
	
//	let offImage:NSImage? =
//	{
//		if #available(macOS 11, *)
//		{
//			let off = NSImage(systemSymbolName:"star", accessibilityDescription:nil)
//			off?.tint = NSColor.systemYellow
//			off?.isTemplate = true
//			return off
//		}
//
//		return nil
//	}()


//	let onImage:NSImage? =
//	{
//		if #available(macOS 11, *)
//		{
//			let off = NSImage(systemSymbolName:"star.fill", accessibilityDescription:nil)
//			off?.tint = NSColor.systemYellow
//			off?.isTemplate = true
//			return off
//		}
//
//		return nil
//	}()
	

//----------------------------------------------------------------------------------------------------------------------


	override func mouseDown(with event:NSEvent)
	{
		var mouse = event.locationInWindow
		mouse = self.convert(mouse, to:self)
		self.setRating(for:mouse)
	}
	
	override func mouseMoved(with event:NSEvent)
	{
		var mouse = event.locationInWindow
		mouse = self.convert(mouse, to:self)
		self.setRating(for:mouse)
	}
	
	override func mouseUp(with event:NSEvent)
	{
		var mouse = event.locationInWindow
		mouse = self.convert(mouse, to:self)
		self.setRating(for:mouse)
	}
	
	func setRating(for mouse:CGPoint)
	{
		let i = Int(mouse.x / size)
		self.rating.wrappedValue = i
		self.needsDisplay = true
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
