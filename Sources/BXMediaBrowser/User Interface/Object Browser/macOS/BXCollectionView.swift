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


class BXCollectionView : QuicklookCollectionView
{
//	public var willSetFrameSizeHandler:((NSSize)->Void)? = nil
//
//	override open func setFrameSize(_ newSize:NSSize)
//	{
//		self.willSetFrameSizeHandler?(newSize)
//		super.setFrameSize(newSize)
//	}

	// Pressing Cmd-I shows the Get Info popover
	
	override public func keyDown(with event:NSEvent)
	{
		if event.charactersIgnoringModifiers == "i" && event.modifierFlags.contains(.command)
		{
			let indexPaths = self.selectionIndexPaths

			if indexPaths.count == 1, let indexPath = indexPaths.first, let item = self.item(at:indexPath) as? ObjectCell
			{
				item.getInfo()
			}
		}
		else
		{
			super.keyDown(with:event)
		}
	}
	
}


//----------------------------------------------------------------------------------------------------------------------


public class BXScrollView : NSScrollView
{
//	public var willSetFrameSizeHandler:((NSSize)->Void)? = nil
//
//	override open func setFrameSize(_ newSize:NSSize)
//	{
//		self.willSetFrameSizeHandler?(newSize)
//		super.setFrameSize(newSize)
//	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
