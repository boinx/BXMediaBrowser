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

import BXSwiftUtils
import BXSwiftUI
import SwiftUI
import AppKit
import QuickLookUI


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
			
			DispatchQueue.main.asyncIfNeeded
			{
				self.redraw()
			}
		}
	}
	
	/// This externally supplied handler is called when the cell is double-clicked
	
	var doubleClickHandler:(()->Void)? = nil
	
	// Outlets to subviews
	
	@IBOutlet var ratingView:ObjectRatingView?
	@IBOutlet var useCountView:NSImageView?

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
		Bundle.BXMediaBrowser
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
		
		self.observers += object.$thumbnailImage.receive(on:RunLoop.main).sink
		{
			[weak self] _ in DispatchQueue.main.asyncIfNeeded { self?.redraw() }
		}
		
		// When statistics for our object change also redraw
		
		self.observers += NotificationCenter.default.publisher(for:StatisticsController.didChangeNotification, object:object).sink
		{
			[weak self] _ in DispatchQueue.main.asyncIfNeeded { self?.redraw() }
		}
			
		// Configure context menu
		
		if let objectView = self.view as? ObjectView
		{
			objectView.contextMenuFactory =
			{
				[weak self] in
				guard let self = self else { return nil }
				guard let collectionView = self.collectionView as? QuicklookCollectionView else { return nil }
				collectionView.selectItemIfNeeded(self)
				return self.buildContextMenu(for:objectView, object:object)
			}
		}
		
		// Configure double-click
		
		self.setupDoubleClick()
		
		// Configure mouse over behavior for rating control
		
		self.setupRatingControl()
	}
	

	/// A double-click on the thumbnail executes the externally supplied doubleClickHandler.
	
	func setupDoubleClick()
	{
		let doubleClick = NSClickGestureRecognizer(target:self, action:#selector(onDoubleClick(_:)))
		doubleClick.numberOfClicksRequired = 2
		doubleClick.delaysPrimaryMouseButtonEvents = false
		self.view.addGestureRecognizer(doubleClick)
	}
	
	/// Configures behavior when mouse moves over this cell. Default implementation hides the textfield
	/// (filename) and shows the 5-star rating control.
	
	func setupRatingControl()
	{
		self.ratingView?.rating = Binding<Int>(
			get:{ self.object?.rating ?? 0 },
			set:{ self.object?.rating = $0 }
		)
		
		self.showRatingControl(false)

		(self.view as? ObjectView)?.mouseHoverHandler =
		{
			[weak self] in self?.showRatingControl($0)
		}
	}
	
	/// Toggles between name field and rating control
	
	open func showRatingControl(_ isInside:Bool)
	{
		let showRating = isInside || self.object.rating > 0
		self.textField?.isHidden = showRating
		self.ratingView?.isHidden = !showRating
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
	
	
	/// Builds a context menu for the specified view and Object
	
	open func buildContextMenu(for view:NSView, object:Object) -> NSMenu?
	{
		let menu = NSMenu()
		
		self.addMenuItem(menu:menu, title:"Get Info")
		{
			[weak self] in self?.getInfo()
		}
			
		self.addMenuItem(menu:menu, title:"Quick Look")
		{
			[weak self] in self?.quickLook()
		}
			
		if let folderObject = object as? FolderObject
		{
			self.addMenuItem(menu:menu, title:"Reveal in Finder")
			{
				folderObject.revealInFinder()
			}
		}
		else if let musicObject = object as? MusicObject, musicObject.previewItemURL != nil
		{
			self.addMenuItem(menu:menu, title:"Reveal in Finder")
			{
				musicObject.revealInFinder()
			}
		}
		
		return menu
	}


	/// Adds a new menu item with the specified title and action
	
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
	
	
	/// Shows the "Get Info" popover anchored on the view of this cell
	
	open func getInfo()
	{
		// Choose the area of this cell where to display the popover
		
		let rootView = self.imageView?.subviews.first ?? self.view
		let rect = rootView.bounds.insetBy(dx:20, dy:20)
		let colorScheme = view.effectiveAppearance.colorScheme
		
		// Create the info view
		
		let infoView = ObjectInfoView(with:object)
			.environment(\.colorScheme,colorScheme)
			
		// Wrap it a popover and display it
		
		let popover = BXPopover(with:infoView, style:.system, colorScheme:.light)
		popover.show(relativeTo:rect, of:rootView, preferredEdge:.maxY)
	}
	
	
	/// Toggles the Quicklook panel for this NSCollectionView
	
	open func quickLook()
	{
		guard let collectionView = self.collectionView as? QuicklookCollectionView else { return }
		collectionView.quicklook()
	}
	
	/// By default this function calls quicklook(), but subclasses can override this method to implement
	/// a different preview mechanism.
	
	open func preview(with event:NSEvent?)
	{
		self.quickLook()
	}
	
	/// Called when this cell is double-clicked. If a doubleClickHandler is set then it will be called,
	/// otherwise the preview() function is called.
	
	@IBAction func onDoubleClick(_ sender:Any?)
	{
		if let doubleClickHandler = self.doubleClickHandler
		{
			doubleClickHandler()
		}
		else
		{
			self.preview(with:NSApp.currentEvent)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - QuickLook


extension ObjectViewController : QLPreviewItem
{
	@MainActor public var previewItemURL:URL!
    {
		self.object.previewItemURL
    }

	@MainActor public var previewItemTitle:String!
    {
		self.object.name
    }

	@MainActor public var previewScreenRect:NSRect
	{
		guard let view = self.imageView?.subviews.first else { return .zero }
		guard let window = view.window else { return .zero }
		let localRect = view.bounds
		let windowRect = view.convert(localRect, to:nil)
		let screenRect = window.convertToScreen(windowRect)
		return screenRect
	}
	
	@MainActor public var previewTransitionImage:Any!
	{
		guard let thumbnail = self.object.thumbnailImage else { return nil }
		return NSImage(cgImage:thumbnail, size:.zero)
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
