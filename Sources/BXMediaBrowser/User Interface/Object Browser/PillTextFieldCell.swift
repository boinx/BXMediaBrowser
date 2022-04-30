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


//----------------------------------------------------------------------------------------------------------------------


class PillTextFieldCell : NSTextFieldCell
{
	override open func draw(withFrame frame:NSRect, in controlView: NSView)
	{
		var rect = frame.insetBy(dx:0.5, dy:0.5)
		let d =	min(rect.width, rect.height)
		let r = 0.5 * d
		
		if self.stringValue.count < 2
		{
			rect.origin.x = NSMidX(frame) - r
			rect.origin.y = NSMidY(frame) - r
			rect.size.width = d
			rect.size.height = d
		}
		
		let path = NSBezierPath(roundedRect:rect, xRadius:r, yRadius:r)
		(self.backgroundColor ?? .systemGreen).set()
		path.fill()
		
		super.draw(withFrame:frame, in:controlView)
	}
	
	override open func drawInterior(withFrame frame:NSRect, in controlView:NSView)
	{
		let rect = frame.offsetBy(dx:0, dy:2)
		super.drawInterior(withFrame:rect, in:controlView)
	}
}


//----------------------------------------------------------------------------------------------------------------------

#endif