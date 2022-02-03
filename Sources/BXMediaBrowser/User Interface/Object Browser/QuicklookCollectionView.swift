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
import QuickLookUI


//----------------------------------------------------------------------------------------------------------------------


class QuicklookCollectionView : NSCollectionView, QLPreviewPanelDataSource , QLPreviewPanelDelegate
{
	// Pressing the spacebar key toggles the QLPreviewPanel
	
	override public func keyDown(with event:NSEvent)
	{
		if event.charactersIgnoringModifiers == " "
		{
			self.quickLook()
		}
		else
		{
			super.keyDown(with:event)
		}
	}
	
	
	/// Toggles the visibility of the QLPreviewPanel
	
	func quickLook()
	{
		guard let panel = QLPreviewPanel.shared() else { return }
		
        if !panel.isVisible
        {
             panel.makeKeyAndOrderFront(nil)
        }
        else
        {
			panel.orderOut(nil)
        }
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -

	// This subclass will always accept responsibility for QLPreviewPanel
	
	override public func acceptsPreviewPanelControl(_ panel:QLPreviewPanel!) -> Bool
	{
        return true
	}

	// Start servicing the QLPreviewPanel
	
    override public func beginPreviewPanelControl(_ panel:QLPreviewPanel!)
    {
        panel.dataSource = self
        panel.delegate = self
    }

	// Stop servicing the QLPreviewPanel
	
    override public func endPreviewPanelControl(_ panel:QLPreviewPanel!)
    {
        panel.dataSource = nil
        panel.delegate = nil
    }
    

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - QLPreviewPanelDataSource


	// Use all selected items for the preview
	
	public func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int
	{
		self.selectionIndexPaths.count
	}
	
	// Return the correct selected item. Please note that selectionIndexPaths returns a Set - which needs to
	// be converted to Array and sorted, to achieve stable results.
	
	public func previewPanel(_ panel:QLPreviewPanel!, previewItemAt index:Int) -> QLPreviewItem!
	{
		let indexPaths = Array(self.selectionIndexPaths).sorted()
		let indexPath = indexPaths[index]
		guard let objectViewController = self.item(at:indexPath) as? ObjectViewController else { return nil }
		return objectViewController
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - QLPreviewPanelDelegate


	// Return the screen rect for the panel zoom animation. Object subclasses can customize the rect
	
	public func previewPanel(_ panel:QLPreviewPanel!, sourceFrameOnScreenFor item:QLPreviewItem!) -> NSRect
	{
		guard let objectViewController = item as? ObjectViewController else { return .zero }
		return objectViewController.previewScreenRect
	}
	
	// Returns an NSImage for the panel zoom animation. Not sure if this really has an effect.
	
	public func previewPanel(_ panel:QLPreviewPanel!, transitionImageFor item:QLPreviewItem!, contentRect:UnsafeMutablePointer<NSRect>!) -> Any!
	{
		guard let objectViewController = item as? ObjectViewController else { return nil }
		return objectViewController.previewTransitionImage
	}
	
	// If we have a multiple selected items, the arrow left/right keys page between the selected items.
	// In the case of a single selection however, we want to pass on the key presses to the NSCollectionView
	// itself, so that the selected is changed. The QLPreviewPanel will be updated accordingly.
	
	public func previewPanel(_ panel:QLPreviewPanel!, handle event:NSEvent!) -> Bool
	{
		if self.selectionIndexPaths.count == 1
		{
			if event.type == .keyDown
			{
				self.keyDown(with:event)
				panel.reloadData()
				return true
			}
			else if event.type == .keyUp
			{
				self.keyUp(with:event)
				panel.reloadData()
				return true
			}
		}
		
		return false
	}
}


//----------------------------------------------------------------------------------------------------------------------
#endif

