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


open class ObjectViewController : NSCollectionViewItem
{
	/// The data model for this cell
	
	public var object:Object!
	{
		didSet
		{
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
	@IBOutlet var useCountView:NSTextField?

	/// References to subscriptions
	
	var observers:[Any] = []
	

//----------------------------------------------------------------------------------------------------------------------


	/// The width of this cell
	
	class var width:CGFloat { 120 }
	
	/// The height of this cell
	
	class var height:CGFloat { 96 }
	
	/// Spacing between cells (both horizontal and vertical)
	
	class var spacing:CGFloat { 10 }


//----------------------------------------------------------------------------------------------------------------------


	/// The identifier can be used with makeItem() in the NSCollectionView datasource
	
    open class var identifier:NSUserInterfaceItemIdentifier
    {
    	NSUserInterfaceItemIdentifier("BXMediaBrowser.\(Self.self)")
	}

	// Look for a Nib file with the same name as the class.
	
	override open var nibName:NSNib.Name?
    {
		"\(Self.self)"
	}

	// Look for the Nib file in the BXMediaBrowser bundle instead of the app bundle
	
	override open var nibBundle:Bundle?
    {
		Bundle.BXMediaBrowser
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns true if our Object is enabled and thus fully usable
	
	open var isEnabled:Bool
	{
		self.object?.isEnabled ?? false
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
	
	open func setup()
	{
		guard let object = object else { return }

		// Load the view lazily
		
		_ = self.view

		// Reset
		
		self.imageView?.image = nil
		self.textField?.stringValue = ""

		// Load the Object thumbnail and metadata
		
		self.loadIfNeeded()

		// Once loaded redraw the view
		
		self.observers = []
		
		self.observers += object.$thumbnailImage.receive(on:RunLoop.main).sink
		{
			[weak self] _ in DispatchQueue.main.asyncIfNeeded { self?.redraw() }
		}
		
		// Redraw when the isEnabled state changes
		
		self.observers += object.$isEnabled.receive(on:RunLoop.main).sink
		{
			[weak self] _ in DispatchQueue.main.asyncIfNeeded
			{
				self?.redraw()
				self?.updateTooltip()
			}
		}
		
		// When statistics for our object change also redraw
		
		self.observers += NotificationCenter.default.publisher(for:StatisticsController.didChangeNotification, object:nil).sink
		{
			[weak self] notification in
			guard let self = self else { return }
			
			var shouldRedraw = notification.object == nil

			if let id = notification.object as? String, id == object.identifier
			{
				shouldRedraw = true
			}
			
			if shouldRedraw
			{
				DispatchQueue.main.asyncIfNeeded { self.redraw() }
			}
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
		
		// Initial state
		
		self.setupDoubleClick()
		self.setupRatingControl()
		self.updateTooltip()
	}
	

	/// Configures auto-layout for the use count icon
	
	func setupUseCountLayout()
	{
		if let useCountView = useCountView, let thumbnail = self.imageView?.subviews.first
		{
			useCountView.constraints.forEach { $0.isActive = false }
			
			useCountView.translatesAutoresizingMaskIntoConstraints = false
			useCountView.trailingAnchor.constraint(equalTo:thumbnail.trailingAnchor, constant:-4).isActive = true
			useCountView.topAnchor.constraint(equalTo:thumbnail.topAnchor, constant:4).isActive = true
			useCountView.heightAnchor.constraint(equalToConstant:18).isActive = true
			useCountView.widthAnchor.constraint(greaterThanOrEqualTo:useCountView.heightAnchor, constant:0).isActive = true
		}
	}
	

	/// A double-click on the thumbnail executes the externally supplied doubleClickHandler.
	
	func setupDoubleClick()
	{
		if isEnabled
		{
			let doubleClick = NSClickGestureRecognizer(target:self, action:#selector(onDoubleClick(_:)))
			doubleClick.numberOfClicksRequired = 2
			doubleClick.delaysPrimaryMouseButtonEvents = false
			self.view.addGestureRecognizer(doubleClick)
		}
		else
		{
			self.view.gestureRecognizers.forEach { self.view.removeGestureRecognizer($0) }
		}
	}
	
	/// Configures behavior when mouse moves over this cell. Default implementation hides the textfield
	/// (filename) and shows the 5-star rating control.
	
	func setupRatingControl()
	{
		self.ratingView?.rating = Binding<Int>(
			get:{ self.object?.rating ?? 0 },
			set:{ self.object?.rating = $0 }
		)

		(self.view as? ObjectView)?.mouseHoverHandler =
		{
			[weak self] in self?.showRatingControl($0)
		}
		
		self.showRatingControl(false)
	}
	
	/// Toggles between name field and rating control
	
	open func showRatingControl(_ isInside:Bool)
	{
		let rating = self.object?.rating ?? 0
		let showRating = isInside || rating > 0
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


	/// Sets a new tooltip on the cell
	
	open func updateTooltip()
	{
		// To be overridden in subclasses
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Event Handling
	
	
	/// Builds a context menu for the specified view and Object
	
	open func buildContextMenu(for view:NSView, object:Object) -> NSMenu?
	{
		guard self.isEnabled else { return nil }

		let menu = NSMenu()
		
		
		self.addMenuItem(menu:menu, title:NSLocalizedString("Get Info", bundle:.BXMediaBrowser, comment:"Menu Item"))
		{
			[weak self] in self?.getInfo()
		}
			
		self.addMenuItem(menu:menu, title:NSLocalizedString("Quick Look", bundle:.BXMediaBrowser, comment:"Menu Item"))
		{
			[weak self] in self?.quickLook()
		}
			
		if let folderObject = object as? FolderObject
		{
			self.addMenuItem(menu:menu, title:NSLocalizedString("Reveal in Finder", bundle:.BXMediaBrowser, comment:"Menu Item"))
			{
				folderObject.revealInFinder()
			}
		}
		else if let musicObject = object as? MusicObject, musicObject.previewItemURL != nil
		{
			self.addMenuItem(menu:menu, title:NSLocalizedString("Reveal in Finder", bundle:.BXMediaBrowser, comment:"Menu Item"))
			{
				musicObject.revealInFinder()
			}
		}
		else if object is PhotosObject
		{
			menu.addItem(NSMenuItem.separator())
			
			self.addMenuItem(menu:menu, title:NSLocalizedString("Show Filenames", bundle:.BXMediaBrowser, comment:"Menu Item"), state:Photos.displayFilenames ? .on : .off)
			{
				Photos.displayFilenames.toggle()
			}
		}
		
		return menu
	}


	/// Adds a new menu item with the specified title and action
	
	func addMenuItem(menu:NSMenu?, title:String, state:NSControl.StateValue = .off, action:@escaping ()->Void)
	{
		guard let menu = menu else { return }
		
		let wrapper = ActionWrapper(action:action)
		
		let item = NSMenuItem(title:title, action:nil, keyEquivalent:"")
		item.representedObject = wrapper
		item.target = wrapper
		item.action = #selector(ActionWrapper.execute(_:))
		item.state = state
		menu.addItem(item)
	}
	
	
	/// Shows the "Get Info" popover anchored on the view of this cell
	
	open func getInfo()
	{
		guard self.isEnabled else { return }

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
		guard self.isEnabled else { return }

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
		guard self.isEnabled else { return }

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
