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


public class AudioCell : ObjectCell
{
	// Outlets
	
    @IBOutlet weak open var button: NSButton?
    @IBOutlet weak open var nameField: NSTextField?
    @IBOutlet weak open var metadataField: NSTextField?
    @IBOutlet weak open var durationField: NSTextField?


//----------------------------------------------------------------------------------------------------------------------


    override class var identifier:NSUserInterfaceItemIdentifier
    {
    	NSUserInterfaceItemIdentifier("BXMediaBrowser.AudioCell")
	}
	
	override class var width:CGFloat { 0 } // 0 means full width of view
	
	override class var height:CGFloat { 54 }
	
	override class var spacing:CGFloat { 0 }


//----------------------------------------------------------------------------------------------------------------------


	override func redraw()
	{
		guard let object = object else { return }

		self.nameField?.stringValue = object.name
		self.metadataField?.stringValue = object.identifier
		self.durationField?.stringValue = "0:00:00"
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
    override public var isSelected:Bool
    {
        didSet { self.updateHighlight() }
    }

	override public var highlightState:NSCollectionViewItem.HighlightState
    {
        didSet { self.updateHighlight() }
    }

    private func updateHighlight()
    {
        guard isViewLoaded else { return }

		let isHilited = self.isSelected	|| self.highlightState != .none
		let backgroundColor = isHilited ? NSColor.systemBlue : NSColor.clear
		let textColor = isHilited ? NSColor.white : NSColor.textColor

		self.view.layer?.backgroundColor = backgroundColor.cgColor
		nameField?.textColor = textColor
		metadataField?.textColor = textColor
		durationField?.textColor = textColor
    }
}


//----------------------------------------------------------------------------------------------------------------------


#endif
