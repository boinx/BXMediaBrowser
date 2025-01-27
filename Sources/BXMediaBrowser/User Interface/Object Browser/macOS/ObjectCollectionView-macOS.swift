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
import SwiftUI
import AppKit
import QuickLookUI


//----------------------------------------------------------------------------------------------------------------------


/// This subclass of NSCollectionView can display the Objects of a Container

public struct ObjectCollectionView<Cell:ObjectCell> : NSViewRepresentable
{
	// This NSViewRepresentable doesn't return a single view, but a whole hierarchy:
	//
	// 	 NSScrollView
	//	    NSClipView
	//	       BXObjectCollectionView
	
	public typealias NSViewType = NSScrollView
	
	/// The Library has properties that may affect the display of this view
	
	@ObservedObject var librarySelection:BXMediaBrowser.Library.Selection

	/// The objects of this Container are displayed in the NSCollectionView
	
	private var container:Container? { librarySelection.container }
	
	/// The class type of the ObjectViewController to be displayed in this NSCollectionView
	
	private let cellType:Cell.Type

	/// The UIState contains the thumbnailScale
	
	private var uiState:UIState
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates ObjectCollectionView with the specified Container and cell type
	
	public init(librarySelection:BXMediaBrowser.Library.Selection, cellType:Cell.Type, uiState:UIState)
	{
		self.librarySelection = librarySelection
		self.cellType = cellType
		self.uiState = uiState
	}
	
	/// Builds a view hierarchy with a NSScrollView and a NSCollectionView inside
	
	public func makeNSView(context:Context) -> NSScrollView
	{
		let collectionView = BXObjectCollectionView(frame:.zero)
 		
		// Configure layout
		
		self.registerCellType(for:collectionView)

		do
		{
			try NSException.toSwiftError
			{
				let layout = self.createLayout(for:collectionView)
				collectionView.collectionViewLayout = layout
				collectionView.backgroundColors = [.clear]
			}
        }
        catch
        {
			BXMediaBrowser.log.error {"\(Self.self).\(#function) ERROR \(error)"}
        }
        
        // Configure selection handling
        
		collectionView.isSelectable = true
		collectionView.allowsEmptySelection = true
		collectionView.allowsMultipleSelection = true
		
		// Configure data source
		
		self.configureDataSource(for:collectionView, coordinator:context.coordinator)
		
		// Configure drag & drop
		
		collectionView.delegate = context.coordinator
        collectionView.setDraggingSourceOperationMask([.copy], forLocal:true)
        collectionView.setDraggingSourceOperationMask([.copy], forLocal:false)
		FolderDropDestination.registerDragTypes(for:collectionView)
		
		// Wrap in a NSScrollView
		
		let scrollView = NSScrollView(frame:.zero)
		scrollView.documentView = collectionView
		scrollView.borderType = .noBorder
		scrollView.hasVerticalScroller = true
		scrollView.contentView.drawsBackground = false
		scrollView.drawsBackground = false
		scrollView.backgroundColor = .clear
 		scrollView.identifier = NSUserInterfaceItemIdentifier("BXMediaBrowser.ObjectBrowserView")

		// Check for missing thumbnail during scrolling and reload then when necessary
		
		scrollView.postsFrameChangedNotifications = true
		scrollView.contentView.postsBoundsChangedNotifications = true
		
		collectionView.observers += NotificationCenter.default.publisher(for:NSView.frameDidChangeNotification, object:scrollView)
			.debounce(for: 1.0, scheduler:DispatchQueue.main)
			.sink
			{
				_ in collectionView.reloadMissingThumbnails()
			}

		collectionView.observers += NotificationCenter.default.publisher(for:NSView.boundsDidChangeNotification, object:scrollView.contentView)
			.debounce(for: 1.0, scheduler:DispatchQueue.main)
			.sink
			{
				_ in collectionView.reloadMissingThumbnails()
			}

		return scrollView
	}
	
	
	// The selected Container has changed, pass it on to the Coordinator
	
	public func updateNSView(_ scrollView:NSScrollView, context:Context)
	{
		guard let collectionView = scrollView.documentView as? BXObjectCollectionView else { return }
		let coordinator = context.coordinator

		coordinator.uiState = self.uiState
		
		// Register new CellType
		
		self.registerCellType(for:collectionView)

		// Update layout for CellType
		
		context.coordinator.updateLayoutHandler =
		{
			guard collectionView.bounds.width > 0.0 else { return }
			
			do
			{
				try NSException.toSwiftError
				{
					let pos = self.saveScrollPos(for:collectionView)
					defer { self.restoreScrollPos(for:collectionView, with:pos) }
				
					let layout = self.createLayout(for:collectionView)
					collectionView.collectionViewLayout = layout
				}
			}
			catch
			{
				BXMediaBrowser.log.error {"\(Self.self).\(#function) ERROR \(error)"}
			}
		}
		
		// Observe view size changes so that layout can be adjusted as needed
		
//		scrollView.willSetFrameSizeHandler =
//		{
//			[weak coordinator] newSize in
//			guard let coordinator = coordinator else { return }
//			guard coordinator.needsUpdateLayout(for:newSize) else { return }
//			coordinator.updateLayoutHandler?()
//		}
			
		coordinator.updateLayoutHandler?()
		coordinator.cellType = self.cellType
		
		// Setting the Container triggers reload of NSCollectionView of the datasource, so this must be done last
		
		context.coordinator.container = self.container
		
	}
	
	/// Creates the Coordinator which provides persistant state to this view
	
	public func makeCoordinator() -> Coordinator
    {
		return Coordinator(container:container, cellType:cellType, uiState:uiState)
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Setup

// ATTENTION
// ---------

// The layout created by this function contains a nasty edge case bug that causes an exception inside Apple's
// layout solving code, and thus leads to a crash: When using an .absolute(cellWidth) the layout is fine as
// long as the view is wide enough to accommodate at least one cell. But when resizing the view (by resizing
// the window or the sidebar), so that it gets narrower that one cell, creating and assigning a new layout
// causes the exception and thus a crash.

// WORKAROUNDS
// -----------

// 1) Using .fractionalWidth layout does not exhibit the crashing behavior. One known workaround to avoiding the
// crash is to switch to .fractionalWidth(1.0) layout BEFORE reaching the small view width. The only way I figured
// out was to apply a "safety" margin e.g. 10pt, so when reaching the safety size, we switch to .fractionalWidth
// layout. That way we are already at .fractionalWidth when reaching the fatal small view size and the crash is
// avoided. However, if the user moves the mouse really fast when resizing the view, we go from a large view size
// to a fatally small one in one step, any we never make the required switch to .fractionalWidth beforehand!

// 2) Another workaround would be to stop using .absolute layout altogehter and simulate its behavior with the
// safer .fractionalWidth layout. However, I never managed to get the exact same behavior. It always came with
// some undesirable side effects, so it's not implemented here.

// 3) A third workaround would be to disallow resizing the view to fatally small sizes at the UI level - e.g. by
// applying frame(minWidth:...) in SwitftUI views. Unless we can discover a better solution this will be the
// chosen workaround for now - so look for minWidth constraints at other places in the UI classes. It should be
// marked width a WORKAROUND 3 comment.
	
extension ObjectCollectionView
{
	public static var minWidth:CGFloat { ImageObjectCell.maxThumbnailSize + 2 * ImageObjectCell.spacing }
	
	/// Creates a NSCollectionViewCompositionalLayout that looks similar to regular flow layout
	
    private func createLayout(for collectionView:NSCollectionView, newSize:NSSize? = nil) -> NSCollectionViewLayout
    {
		let w:CGFloat = floor(cellType.width)
		let h:CGFloat = floor(cellType.height)
		let d:CGFloat = floor(cellType.spacing)
        let ratio = (w/h).validated(fallbackValue:0.75)
		
		let viewWidth = newSize?.width ?? collectionView.bounds.width
		let maxCellWidth = floor(max(32.0, viewWidth - 2*d - 2))	// view width determines maximum size - in case of 0 width view enforce a maxCellWidth>0 or we crash!
		let minCellWidth = floor(min(70.0, maxCellWidth))			// 70 is the minimum width to display ObjectRatingView without clipping
		
		let size = self.uiState.thumbnailSize
		let cellWidth = floor(size.clipped(to:minCellWidth...maxCellWidth))
		let cellHeight = floor((cellWidth/ratio).validated(fallbackValue:h))
		
		// Item (cell)
		
		var itemWidth:NSCollectionLayoutDimension
		var itemHeight:NSCollectionLayoutDimension
        var item:NSCollectionLayoutItem
		
		if w == 0	// Use full view width and hard-coded height as specified (used for AudioObjectCells)
		{
			itemWidth = .fractionalWidth(1.0)
			itemHeight = .absolute(h)
			item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension:itemWidth, heightDimension:itemHeight))
		}
//        else if cellWidth >= maxWidth-10 || viewWidth < minWidth // WORKAROUND 1 (see above)
//        {
//            itemWidth = .fractionalWidth(1.0)
//            itemHeight = .fractionalWidth(1.0/ratio)
//            item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension:itemWidth, heightDimension:itemHeight))
//        }
        else	// ImageObjectCells use calculated size (cellWidth,cellHeight)
        {
            itemWidth = .absolute(cellWidth)
            itemHeight = .absolute(cellHeight)
            item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension:itemWidth, heightDimension:itemHeight))
        }
		
		// Group (row)
		
        let groupSize = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1.0), heightDimension:itemHeight)
//		let group = NSCollectionLayoutGroup.horizontal(layoutSize:groupSize, subitem:item, count:1) // To avoid edge case crashes do not call with subitems:[item], but instead call with fixed count=1. Fore more refer to https://stackoverflow.com/questions/63748268/uicollectionviewdiffabledatasource-crash-invalid-parameter-not-satisfying-item
		let group = NSCollectionLayoutGroup.horizontal(layoutSize:groupSize, subitems:[item])
		group.interItemSpacing = .fixed(d)
		
		// Section
		
        let section = NSCollectionLayoutSection(group:group)
        section.interGroupSpacing = d
        section.contentInsets = NSDirectionalEdgeInsets(top:d, leading:d, bottom:d, trailing:d)
        
        // View
        
        return NSCollectionViewCompositionalLayout(section:section)
    }


	/// Creates a NSCollectionViewDiffableDataSource. The Coordinator will is the owner of the datasource,
	/// since it also has access to the data model.
	
    @MainActor private func configureDataSource(for collectionView:NSCollectionView, coordinator:Coordinator)
    {
		// Setup the cell provider for the dataSource
		
        coordinator.dataSource = NSCollectionViewDiffableDataSource<Int,Object>(collectionView:collectionView)
        {
			[weak coordinator] (collectionView:NSCollectionView, indexPath:IndexPath, identifier:Object) -> NSCollectionViewItem? in
			return coordinator?.cell(for:collectionView, indexPath:indexPath, identifier:identifier)
		}

        // Set initial data
        
        var snapshot = NSDiffableDataSourceSnapshot<Int,Object>()
        snapshot.appendSections([0])
        snapshot.appendItems([], toSection:0)
        coordinator.dataSource.apply(snapshot, animatingDifferences:false)
    }
    
    /// Register the NSViewController class for the current cellType identifier
	
    private func registerCellType(for collectionView:NSCollectionView)
    {
		let identifier = self.cellType.identifier
        collectionView.register(self.cellType, forItemWithIdentifier:identifier)
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Scrolling

extension ObjectCollectionView
{
    /// Saves the current scroll position, returning a tuple with the current bounds and visibleRect
	
    func saveScrollPos(for collectionView:NSCollectionView) -> (CGRect,CGRect)
    {
		let bounds = collectionView.bounds
		let visible = collectionView.visibleRect
		return (bounds,visible)
    }
    
    
    /// Restores the scroll position with the tuple of the old bounds and visibleRect.
	///
	/// This function tries to keep the visible cells centered, while the thumbnail scale is changing.
	
    func restoreScrollPos(for collectionView:NSCollectionView, with old:(CGRect,CGRect))
    {
		let oldBounds = old.0
		let oldVisible = old.1
		let oldY = oldVisible.midY
		let oldH = oldBounds.height
		guard oldH > 0.0 else { return }

		let fraction = (oldY - oldBounds.minY) / oldH
		let newBounds = collectionView.bounds
		var newVisible = collectionView.visibleRect
		let newY = newBounds.minY + fraction * newBounds.height
		newVisible.origin.y = newY - 0.5 * newVisible.height
		
		collectionView.scroll(newVisible.origin)
    }
}


extension NSCollectionView
{
	/// This notification is sent when Objects are selected
		
	public static let didSelectObjects = NSNotification.Name("NSCollectionView.didSelectObjects")

	/// This notification is sent when the user scrolls down to the bottom
		
	public static let didScrollToEnd = NSNotification.Name("NSCollectionView.didScrollToEnd")
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Coordinator
	
extension ObjectCollectionView
{
	public class Coordinator : NSObject, NSCollectionViewDelegate
    {
		/// The Container is the data model for the NSCollectionView
		
		@MainActor var container:Container? = nil
		{
			didSet
			{
				self.shouldAnimate = false
				self.updateDataSource()
			}
		}
		
		/// The class type of the Object cell to be displayed in this NSCollectionView
	
		@MainActor var cellType:Cell.Type

		/// The UIState is responsible for thumbnailScale
		
		@MainActor var uiState:UIState
		{
			didSet
			{
				self.updateLayout()
			}
		}

		/// This handler is called when the layout needs to be recalculated
		
		@MainActor var updateLayoutHandler:(()->Void)? = nil

		var currentViewSize:CGSize = .zero
		
		/// The dataSource accesses the Objects of the Container
		
		var dataSource: NSCollectionViewDiffableDataSource<Int,Object>! = nil
		
		/// The number of cells that fit inside a single row
		
//		var columnCount = 0
		
		/// Set this property to true if data model changes should be animated in the view (e.g. objects inserted or deleted)
		
		private var shouldAnimate = false
		
		/// References to internal subscriptions
		
		private var layoutObserver:Any? = nil
		internal var frameObserver:Any? = nil
		private var dataSourceObserver:Any? = nil
		
		
//----------------------------------------------------------------------------------------------------------------------


 		// MARK: - Setup
 		
 		
        @MainActor init(container:Container?, cellType:Cell.Type, uiState:UIState)
        {
			self.container = container
			self.cellType = cellType
			self.uiState = uiState
			
			super.init()
        }

		func needsUpdateLayout(for viewSize:CGSize) -> Bool
		{
			let needsUpdate = viewSize.width != currentViewSize.width
			self.currentViewSize = viewSize
			return needsUpdate
		}
		
		@MainActor func updateLayout()
		{
//			self.layoutObserver = uiState.$thumbnailScale
			self.layoutObserver = uiState.$thumbnailSize
				.throttle(for:0.02, scheduler:DispatchQueue.main, latest:true)
				.sink
				{
					[weak self] _ in
					self?.shouldAnimate = true
					self?.updateLayoutHandler?()
				}
		}


//----------------------------------------------------------------------------------------------------------------------


 		// MARK: - Data Source
 		
		/// Updates the dataSource when the data model has been changed
		
		@MainActor func updateDataSource()
		{
			if let container = self.container
			{
				self.dataSourceObserver = container.$objects
					.debounce(for:0.05, scheduler:DispatchQueue.main)
					.sink
					{
						[weak self] objects in
						self?.shouldAnimate = objects.count <= 1000
						self?._updateDataSource()
					}
			}
			
			self._updateDataSource()
		}
		
		/// Updates the dataSource when the data model has been changed
		
		@MainActor func _updateDataSource()
		{
			let objects = self.container?.objects ?? []
			
			var snapshot = NSDiffableDataSourceSnapshot<Int,Object>()
			snapshot.appendSections([0])
			snapshot.appendItems(objects, toSection:0)
			
			do
			{
				try NSException.toSwiftError
				{
					self.dataSource.apply(snapshot, animatingDifferences:shouldAnimate)
				}
			}
			catch let error
			{
				log.error {"\(Self.self).\(#function) ERROR \(error)"}
			}
		}


		/// Returns a cell for the specified Object
		
		@MainActor func cell(for collectionView:NSCollectionView, indexPath:IndexPath, identifier:Object) -> NSCollectionViewItem?
		{
			// Check if indexPath is valid
			
			let n = self.container?.objects.count ?? 0
			let i = indexPath.item
			guard i>=0 && i<n else { return nil }
			
			// Get the object - Please note that the dataSource uses Object directly, because it is Hashable and Equatable
			
			let object = identifier
			
			// Reuse (or create) a cell
			
			let item = collectionView.makeItem(withIdentifier:cellType.identifier, for:indexPath)
			
			// Configure the cell with the model object
			
			if let cell = item as? ObjectCell
			{
				cell.object = object
			}

        	return item
		}
		
		
		// Once the user scrolls down near the bottom of the ObjectCollectionView, then send out a notification that
		// can trigger certain actions (like reloading the Container).
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, willDisplay item:NSCollectionViewItem, forRepresentedObjectAt indexPath:IndexPath)
		{
			guard let container = self.container else { return }
			let n = container.objects.count
			guard n > 0 else { return }
			
			let i = indexPath.item
			let j = (n - 1).clipped(to:0 ... n-1)
			
			if i == j
			{
				NotificationCenter.default.post(name:NSCollectionView.didScrollToEnd, object:container)
			}
		}


		// Apple didn't implement Shift-selection of range in NSCollectionView, so we have to provide this feature by ourself here
		
     	@MainActor public func collectionView(_ collectionView:NSCollectionView, shouldSelectItemsAt indexPaths:Set<IndexPath>) -> Set<IndexPath>
    	{
			// Bail out if this is a drag-rectangle selection with multiple cells being selected
			
			guard indexPaths.count == 1 else
			{
				self.lastClickedIndexPath = nil
				return indexPaths
			}
			
			// Remember last clicked cell
			
			let clickedIndexPath = indexPaths.first
			let prevIndexPath = self.lastClickedIndexPath
			self.lastClickedIndexPath = clickedIndexPath
			
			// If this is a Shift-click and we have a previous and new indexPath, then create the whole range of indexPaths to be selected
			
			guard NSEvent.modifierFlags.contains(.shift) else { return indexPaths }
			guard let clickedIndexPath = clickedIndexPath else { return indexPaths }
			guard let prevIndexPath = prevIndexPath else { return indexPaths }
			
			let j1 = clickedIndexPath[1]
			let j2 = prevIndexPath[1]
			let i1 = min(j1,j2)
			let i2 = max(j1,j2)
			
			var rangeIndexPaths = Set<IndexPath>()
			
			for i in i1 ... i2
			{
				rangeIndexPaths.insert(IndexPath(item:i, section:0))
			}
			
			return rangeIndexPaths
    	}
    	
		@MainActor public func collectionView(_ collectionView:NSCollectionView, shouldDeselectItemsAt indexPaths:Set<IndexPath>) -> Set<IndexPath>
    	{
			self.lastClickedIndexPath = nil
			return indexPaths
    	}
    	
    	private var lastClickedIndexPath:IndexPath? = nil
    	
		// When the selection was changed, update the Quicklook preview panel and notify others
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, didSelectItemsAt indexPaths:Set<IndexPath>)
		{
			self.updatePreviewPanel()
			self.sendDidSelectObjectsNotification(for:collectionView)
		}
		
		
		// Unfortunately the deselect gets called before the select, so we have to delay and check again
		// if we got a new selection, before sending any notifications that announces the delesecting.
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, didDeselectItemsAt indexPaths:Set<IndexPath>)
		{
			DispatchQueue.main.async
			{
				if collectionView.selectionIndexPaths.isEmpty
				{
					self.updatePreviewPanel()
					self.sendDidSelectObjectsNotification(for:collectionView)
				}
			}
		}
		
		
		// After changing the selection, the QLPreviewPanel should be updated (if currently open)
		
		func updatePreviewPanel()
		{
			if let panel = QLPreviewPanel.shared(), panel.isVisible
			{
				panel.reloadData()
			}
		}
		
		
		/// Sends a notification announcing which Objects have been selected
		
		func sendDidSelectObjectsNotification(for collectionView:NSCollectionView)
		{
			let objects = collectionView.selectionIndexPaths
				.compactMap { collectionView.item(at:$0) as? ObjectCell }
				.compactMap { $0.object }
			
			if objects.isEmpty
			{
				NotificationCenter.default.post(name: NSCollectionView.didSelectObjects, object:nil)
			}
			else
			{
				NotificationCenter.default.post(name: NSCollectionView.didSelectObjects, object:objects)
			}
		}
		
		
//----------------------------------------------------------------------------------------------------------------------


		// MARK: - Dragging Source

		// Do not allow drag, if it contains disabled cells (e.g. DRM protected audio)
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, canDragItemsAt indexPaths:Set<IndexPath>, with event:NSEvent) -> Bool
		{
			for indexPath in indexPaths
			{
				if let object = self.object(for:indexPath), !object.isEnabled
				{
					if let cell = collectionView.item(at:indexPath) as? ObjectCell
					{
						cell.showWarningMessage()
					}
					
					return false
				}
			}
			
			return true
		}
		
		
		// Start dragging the Object. Since the Object can be remote, a NSFilePromiseProvider will be returned. The download will be triggered,
		// once the NSFilePromiseProvider is received at the drop destination. Obviously the download is skipped if the Object already points
		// to local file.
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, pasteboardWriterForItemAt indexPath:IndexPath) -> NSPasteboardWriting?
		{
			// Get Object to be dragged
			
			guard let object = self.object(for:indexPath) else { return nil }
			guard object.isEnabled else { return nil }
			
			// Get a file promise from the Object
			
			guard object.isLocallyAvailable || object.isDownloadable else { return nil }
			return object.filePromiseProvider
		}
		
		
		// Prevent item from being hidden (creating a hole in the grid) while being dragged

		@MainActor public func collectionView(_ collectionView:NSCollectionView, draggingSession session:NSDraggingSession, willBeginAt screenPoint:NSPoint, forItemsAt indexPaths:Set<IndexPath>)
		{
			for indexPath in indexPaths
			{
				collectionView.item(at:indexPath)?.view.isHidden = false
			}
		}

		/// Returns the Object for the specified IndexPath
		
		@MainActor func object(for indexPath:IndexPath) -> Object?
		{
			let i = indexPath.item
			guard let objects = self.container?.objects else { return nil }
			guard i>=0 && i<objects.count else { return nil }
			return objects[i]
		}


//----------------------------------------------------------------------------------------------------------------------


 		// MARK: - Dragging Destination

		// Check if the collectionView can receive the dragged files
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, validateDrop draggingInfo:NSDraggingInfo, proposedIndexPath:AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation:UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation
		{
			return self.container?.fileDropDestination?.collectionView(collectionView, validateDrop:draggingInfo, proposedIndexPath:proposedIndexPath, dropOperation:proposedDropOperation) ?? []
		}


		// Copy the dragged files to the Container
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, acceptDrop draggingInfo:NSDraggingInfo, indexPath:IndexPath, dropOperation:NSCollectionView.DropOperation) -> Bool
		{
			return self.container?.fileDropDestination?.collectionView(collectionView, acceptDrop:draggingInfo, indexPath:indexPath, dropOperation:dropOperation) ?? false
		}

	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif

