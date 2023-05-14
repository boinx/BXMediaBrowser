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


open class ObjectCell : NSCollectionViewItem
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
	
	var singleClickHandler:(()->Void)? = nil
	var doubleClickHandler:(()->Void)? = nil
	
	// Outlets to subviews
	
	@IBOutlet var ratingView:ObjectRatingView?
	@IBOutlet var useCountView:NSTextField?

	// Internal housekeeping
	
	var observers:[Any] = []
	var isPopoverOpen = false
	

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

		self.observers += NotificationCenter.default.publisher(for:StatisticsController.ratingNotification, object:self.object).sink
		{
			[weak self] notification in
			guard let self = self else { return }
			
			DispatchQueue.main.asyncIfNeeded
			{
				self.showRatingControl(false)
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
	
	
	func setupTextField(_ textField:NSTextField, size:CGFloat = NSFont.systemFontSize, alignment:NSTextAlignment = .left, alpha:CGFloat = 1.0)
	{
		textField.font = NSFont.systemFont(ofSize:size)
		textField.alignment = alignment
		textField.lineBreakMode = .byTruncatingTail
		textField.drawsBackground = false
		textField.isBezeled = false
		textField.isBordered = false
		textField.isEditable = false
		textField.isSelectable = false
		textField.alphaValue = alpha
	}
	
	
	/// A double-click on the thumbnail executes the externally supplied doubleClickHandler.
	
	func setupDoubleClick()
	{
		self.view.gestureRecognizers.forEach { self.view.removeGestureRecognizer($0) }
		self.imageView?.gestureRecognizers.forEach { self.view.removeGestureRecognizer($0) }

		let singleClick = NSClickGestureRecognizer(target:self, action:#selector(onSingleClick(_:)))
		singleClick.numberOfClicksRequired = 1
		singleClick.delaysPrimaryMouseButtonEvents = false
		self.imageView?.addGestureRecognizer(singleClick)
		
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
		self.ratingView?.needsDisplay = showRating
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
		let menu = NSMenu()
		
		// Standard items
		
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
		
		// Special for Photos App
		
		else if object is PhotosObject
		{
			menu.addItem(NSMenuItem.separator())
			
			self.addMenuItem(menu:menu, title:NSLocalizedString("Show Filenames", bundle:.BXMediaBrowser, comment:"Menu Item"), state:Photos.displayFilenames ? .on : .off)
			{
				Photos.displayFilenames.toggle()
			}
		}
		
		// Set rating on selected objects
		
		menu += NSMenuItem.separator()
		
		menu += NSMenuItem(sectionName:NSLocalizedString("rating", tableName:"Object.Filter", bundle:.BXMediaBrowser, comment:"Sorting Kind Name"))
		
		menu += NSMenuItem(size:CGSize(106,20))
		{
			RatingFilterView(rating:self.ratingBinding)
		}
		
		// Debugging commands (not visible in release builds)
		
		#if DEBUG
		
		menu.addItem(NSMenuItem.separator())
		menu.addItem(NSMenuItem(sectionName:"DEBUG"))

		self.addMenuItem(menu:menu, title:"Purge")
		{
			object.purge()
		}

		self.addMenuItem(menu:menu, title:NSLocalizedString("Reload", bundle:.BXMediaBrowser, comment:"Menu Item"))
		{
			object.load()
		}

		#endif
		
		return menu
	}


	/// Adds a new menu item with the specified title and action
	
	public func addMenuItem(menu:NSMenu?, index:Int? = nil, title:String, state:NSControl.StateValue = .off, action:@escaping ()->Void)
	{
		guard let menu = menu else { return }
		
		let wrapper = ActionWrapper(action:action)
		
		let item = NSMenuItem(title:title, action:nil, keyEquivalent:"")
		item.representedObject = wrapper
		item.target = wrapper
		item.action = #selector(ActionWrapper.execute(_:))
		item.state = state
		
		if let index = index
		{
			menu.insertItem(item, at:index)
		}
		else
		{
			menu.addItem(item)
		}
	}
	
	
	@MainActor var ratingBinding:Binding<Int>
	{
		Binding<Int>(
			get:
			{
				self.object.rating
			},
			set:
			{
				rating in
				guard let collectionView = self.collectionView as? BXObjectCollectionView else { return }
				let selectedObjects = collectionView.selectedCells.compactMap { $0.object }
				selectedObjects.forEach { $0.rating = rating }
			})
	}

	
	/// Shows the "Get Info" popover anchored on the view of this cell
	
	open func getInfo()
	{
		self.showPopover(with: ObjectInfoView(with:object))
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
	
	/// Called when this cell is single-clicked. If a singleClickHandler is set then it will be called
	
	@IBAction func onSingleClick(_ sender:Any?)
	{
		if let singleClickHandler = self.singleClickHandler
		{
			singleClickHandler()
		}
		else if !self.isEnabled
		{
			self.showWarningMessage()
		}
	}
	
	/// Called when this cell is double-clicked. If a doubleClickHandler is set then it will be called,
	/// otherwise the preview() function is called.
	
	@IBAction func onDoubleClick(_ sender:Any?)
	{
		if let doubleClickHandler = self.doubleClickHandler
		{
			doubleClickHandler()
		}
		else if !isEnabled
		{
			self.showWarningMessage()
		}
		else
		{
			self.preview(with:NSApp.currentEvent)
		}
	}
	
	/// Shows a popover anchored at the icon view
	
	open func showPopover<V:View>(with view:V)
	{
		// Choose the area of this cell where to display the popover
		
		let rootView = self.imageView?.subviews.first ?? self.view
		let rect = rootView.bounds.insetBy(dx:20, dy:20)
		let colorScheme = self.view.effectiveAppearance.colorScheme
		
		// Create the view
		
		let popoverView = view
			.environment(\.colorScheme,colorScheme)
			
		// Wrap it a popover and display it
		
		let popover = BXPopover(with:popoverView, style:.system, colorScheme:.light)
		popover.delegate = self
		popover.show(relativeTo:rect, of:rootView, preferredEdge:.maxY)
		
		self.isPopoverOpen = true
	}
	
	
	/// Shows a warning that explains why drag & drop is not allowed
	
	open func showWarningMessage()
	{
		guard !isPopoverOpen else { return }
		
		if object.isDRMProtected
		{
			self.showPopover(with: ObjectWarningView(message:Config.DRMProtectedFile.warningMessage))
		}
		else if object is MusicObject && !object.isLocallyAvailable
		{
			let message = NSLocalizedString("AppleMusic.warning", bundle:.BXMediaBrowser, comment:"Warning Message")
			self.showPopover(with: ObjectWarningView(message:message))
		}
		else if let url = self.object.previewItemURL, url.isCorruptedAppleLoopFile
		{
			self.showPopover(with: ObjectWarningView(message:Config.CorruptedAppleLoops.warningMessage))
		}
		else if object is MusicObject && !object.isEnabled
		{
			if let source = MusicApp.shared.source, let library = MusicApp.shared.library
			{
				let visible = Binding<Bool>.constant(true)
				let view = MusicAccessAlertView(source:source, isPresented:visible)
					.environmentObject(library)
				self.showPopover(with:view)
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - NSPopoverDelegate


extension ObjectCell : NSPopoverDelegate
{
    public func popoverWillShow(_ notification:Notification)
	{
		self.isPopoverOpen = true
	}
	
	public func popoverDidClose(_ notification:Notification)
    {
		self.isPopoverOpen = false
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - QuickLook


extension ObjectCell : QLPreviewItem
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
