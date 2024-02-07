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
import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


public class BXObjectCollectionView : QuicklookCollectionView
{
	public static let getInfoNotification = Notification.Name("BXObjectCollectionView.getInfo")
	public static let selectAllNotification = Notification.Name("BXObjectCollectionView.selectAll")
	public static let deselectAllNotification = Notification.Name("BXObjectCollectionView.deselectAll")
	
	internal var observers:[Any] = []
	
	
//----------------------------------------------------------------------------------------------------------------------


	override public init(frame:NSRect)
	{
		super.init(frame:frame)
		
		self.observers += NotificationCenter.default.publisher(for:Self.getInfoNotification, object:nil).sink
		{
			[weak self] _ in self?.getInfo()
		}
		
		self.observers += NotificationCenter.default.publisher(for:Self.selectAllNotification, object:nil).sink
		{
			[weak self] _ in self?.selectAll(nil)
		}
		
		self.observers += NotificationCenter.default.publisher(for:Self.deselectAllNotification, object:nil).sink
		{
			[weak self] _ in self?.deselectAll(nil)
		}
	}
	
	required init?(coder:NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// Pressing Cmd-I shows the Get Info popover
	
	override public func keyDown(with event:NSEvent)
	{
		if event.charactersIgnoringModifiers == "i" && event.modifierFlags.contains(.command)
		{
			self.getInfo()
		}
		else
		{
			super.keyDown(with:event)
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Display the metadata Info popover for the selected Object
	
	public func getInfo()
	{
		guard let window = self.window else { return }
		guard window.isKeyWindow else { return }
		
		let indexPaths = self.selectionIndexPaths

		if indexPaths.count == 1, let indexPath = indexPaths.first, let item = self.item(at:indexPath) as? ObjectCell
		{
			item.getInfo()
		}
	}
	
	
	/// Returns the list of selected ObjectCells
	
	open var selectedCells:[ObjectCell]
	{
		self.selectionIndexPaths.compactMap
		{
			self.item(at:$0) as? ObjectCell
		}
	}


	/// Checks if any thumbnails of currently visible objects are missing, and reloads them if necessary.
	///
	/// This provides a self-healing effect for a situation that sometimes occurs, but the cause isn't understood yet.
	
	@objc public func reloadMissingThumbnails()
	{
		let visibleItems = self.visibleItems()
		
		for item in visibleItems
		{
			guard let cell = item as? ObjectCell else { continue }
			guard let object = cell.object else { continue }
			
			if object.thumbnailImage == nil
			{
				object.load()
			}
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Selects all object (in all browsers)

	public static func selectAll()
	{
		NotificationCenter.default.post(name:Self.selectAllNotification, object:nil)
	}

	/// Deselects all object (in all browsers)

	public static func deselectAll()
	{
		NotificationCenter.default.post(name:Self.deselectAllNotification, object:nil)
	}

}


//----------------------------------------------------------------------------------------------------------------------


#endif
