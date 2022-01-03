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


public class ImageCell : ObjectCell
{
	static let width:CGFloat = 120
	static let height:CGFloat = 96
	static let spacing:CGFloat = 10


//----------------------------------------------------------------------------------------------------------------------


	/// Redraws the cell by updating the thumbnail and name
	
	override func redraw()
	{
		guard let object = object else { return }

		if let thumbnail = object.thumbnailImage
		{
			let w = thumbnail.width
			let h = thumbnail.height
			let size = CGSize(width:w, height:h)
			self.imageView?.image = NSImage(cgImage:thumbnail, size:size)
		}
	
		self.textField?.stringValue = self.object.name
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
        if !isViewLoaded
        {
            return
        }

		let isHilited = self.isSelected	|| self.highlightState != .none

		if let layer = self.imageView?.subviews.first?.layer
		{
			layer.borderWidth = isHilited ? 4.0 : 0.0
			layer.borderColor = isHilited ? NSColor.systemYellow.cgColor : NSColor.clear.cgColor
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------


#endif
