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


public class BXObjectCollectionView : QuicklookCollectionView
{
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
	
	override public var acceptsFirstResponder:Bool
	{
		true
	}
	
	override public func becomeFirstResponder() -> Bool
	{
		true
	}
	
	override public func resignFirstResponder() -> Bool
	{
		true
	}
	
	open var selectedCells:[ObjectCell]
	{
		self.selectionIndexPaths.compactMap
		{
			self.item(at:$0) as? ObjectCell
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
