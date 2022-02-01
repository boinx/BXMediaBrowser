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


public class ObjectViewController : NSCollectionViewItem
{
	/// The data model for this cell
	
	var object:Object!
	{
		didSet
		{
			self.reset()
			self.setup()
			self.redraw()
		}
	}
	
	/// References to subscriptions
	
	var observers:[Any] = []
	

//----------------------------------------------------------------------------------------------------------------------


	/// The identifier can be used with makeItem() in the NSCollectionView datasource
	
    class var identifier:NSUserInterfaceItemIdentifier
    {
    	NSUserInterfaceItemIdentifier("BXMediaBrowser.\(Self.self)")
	}
	
	/// The width of this cell
	
	class var width:CGFloat { 120 }
	
	/// The height of this cell
	
	class var height:CGFloat { 96 }
	
	/// Spacing between cells (both horizontal and vertical)
	
	class var spacing:CGFloat { 10 }


//----------------------------------------------------------------------------------------------------------------------


	/// The nib name should be the same as the class name
	
	class var nibName:NSNib.Name
	{
		"\(Self.self)"
	}
	
	// These overrides are important or The NSCollectionView will look in the wrong Bundle (main bundle) and
	// crash because it cannot find the nib file.
	
	override open var nibName: NSNib.Name?
    {
		Self.nibName
	}

	override open var nibBundle: Bundle?
    {
		Bundle.module
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
	
	open func reset()
	{
		self.imageView?.image = nil
		self.textField?.stringValue = ""
	}
	
	
	open func setup()
	{
		guard let object = object else { return }

		// Load the Object thumbnail and metadata
		
		self.loadIfNeeded()

		// Once loaded redraw the view
		
		self.observers = []
		
		self.observers += object.$thumbnailImage
			.receive(on:RunLoop.main)
			.sink
			{
				_ in
				self.redraw()
			}
		
		// Configure context menu
		
		if let objectView = self.view as? ObjectView
		{
			objectView.contextMenuFactory =
			{
				[weak self] in self?.buildContextMenu(for:objectView, object:object)
			}
		}
	}
	

	/// Loads the Object thumbnail and metadata into memory
	
    func loadIfNeeded()
    {
		if object.thumbnailImage == nil || object.metadata == nil
		{
			object.load()
		}
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Drawing
	
	
	/// Redraws the cell
	
	open func redraw()
	{
		// To be overridden in subclasses
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Event Handling
	
	
	open func buildContextMenu(for view:NSView, object:Object) -> NSMenu?
	{
		let menu = NSMenu()
		
		self.addMenuItem(menu:menu, title:"Get Info")
		{
			NSSound.beep()
		}
			
		self.addMenuItem(menu:menu, title:"Quick Look")
		{
			NSSound.beep()
		}
			
		if let folderObject = object as? FolderObject
		{
			self.addMenuItem(menu:menu, title:"Reveal in Finder")
			{
				folderObject.revealInFinder()
			}
		}
		
		return menu
	}


	func addMenuItem(menu:NSMenu?, title:String, action:@escaping ()->Void)
	{
		guard let menu = menu else { return }
		
		let wrapper = ActionWrapper(action:action)
		
		let item = NSMenuItem(title:title, action:nil, keyEquivalent:"")
		item.representedObject = wrapper
		item.target = wrapper
		item.action = #selector(ActionWrapper.execute(_:))
		
		menu.addItem(item)
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
