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
	/// Binding to the rating property of the Object
	
	public var rating:Binding<Int> = Binding<Int>.constant(0)
	
	/// Determines how many stars will be drawn
	
	public var maxRating:Int = 5
	
	/// The size of the star image in pt
	
	public var size:CGFloat = 16
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Drawing
	
	
	// When switching between light and dark mode, get rid of cached star icons
	
	override func viewDidChangeEffectiveAppearance()
	{
		super.viewDidChangeEffectiveAppearance()
		Self._offImage = nil
		Self._onImage = nil
	}
	
	// Build the off-star icon lazily
	
	private var offImage:NSImage?
	{
		if Self._offImage == nil
		{
			Self._offImage = Self.image(systemName:"star", color:NSColor.lightGray)
		}
		
		return Self._offImage
	}
	
	private static var _offImage:NSImage? = nil

	// Build the on-star icon lazily
	
	private var onImage:NSImage?
	{
		if Self._onImage == nil
		{
			Self._onImage = Self.image(systemName:"star.fill", color:NSColor.systemYellow)
		}
		
		return Self._onImage
	}
	
	private static var _onImage:NSImage? = nil
	
	/// Creates an icon image with the specified name and color
	
	class func image(systemName:String, color:NSColor) -> NSImage?
	{
		if #available(macOS 11, *)
		{
			guard let icon = NSImage(systemSymbolName:systemName, accessibilityDescription:nil) else { return nil }
			guard let image = icon.copy() as? NSImage else { return nil }
			
			image.lockFocus()
			defer { image.unlockFocus() }
			
			color.set()
			let bounds = NSRect(origin:.zero, size:image.size)
			bounds.fill(using:.sourceAtop)
				
			return image
		}
		else
		{
			return nil
		}
	}
	
	
	// Draws 5 stars, filled or unfilled
	
	override func draw(_ rect:NSRect)
	{
		if #available(macOS 11, *)
		{
			let rating = self.rating.wrappedValue
			var frame = CGRect(x:0, y:0, width:size, height:size)
			
			for i in 1...maxRating
			{
				frame.origin.x = CGFloat(i-1) * size
				frame.origin.y = bounds.maxY - size

				let image = i <= rating ? onImage : offImage
				image?.draw(in:frame)
			}
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Events
	
	override func mouseDown(with event:NSEvent)
	{
		self.setRating(with:mouse(for:event))
	}
	
	override func mouseDragged(with event:NSEvent)
	{
		self.setRating(with:mouse(for:event))
	}
	
	override func mouseUp(with event:NSEvent)
	{
		self.setRating(with:mouse(for:event))
	}
	
	/// Returns the mouse location in this view
	
	func mouse(for event:NSEvent) -> CGPoint
	{
		let mouse = event.locationInWindow
		return self.convert(mouse, from:nil)
	}
	
	/// Sets rating depending on mouse location
	
	func setRating(with mouse:CGPoint)
	{
		let x = mouse.x + size
		let i = Int(x/size)
		self.rating.wrappedValue = i
		self.needsDisplay = true
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
