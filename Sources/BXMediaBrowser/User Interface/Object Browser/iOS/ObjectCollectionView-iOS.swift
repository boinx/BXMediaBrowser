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


#if os(iOS)

import SwiftUI
import UIKit
import BXSwiftUtils
import QuickLookThumbnailing


//----------------------------------------------------------------------------------------------------------------------


extension UICollectionView
{
	/// This notification is sent when Objects are selected
		
	public static let didSelectObjects = NSNotification.Name("UICollectionView.didSelectObjects")

	/// This notification is sent when the user scrolls down to the bottom
		
	public static let didScrollToEnd = NSNotification.Name("UICollectionView.didScrollToEnd")
}


////----------------------------------------------------------------------------------------------------------------------
//
//
///// This subclass of NSCollectionView can display the Objects of a Container
//
//public struct ObjectCollectionView<Cell:ObjectViewController> : NSViewRepresentable
//{
//	// This NSViewRepresentable doesn't return a single view, but a whole hierarchy:
//	//
//	// 	 NSScrollView
//	//	    NSClipView
//	//	       NSCollectionView
//	
//	public typealias NSViewType = NSScrollView
//	
//	/// The Library has properties that may affect the display of this view
//	
////	private var library:Library? = nil
//	
//	/// The objects of this Container are displayed in the NSCollectionView
//	
//	private var container:Container? = nil
//	
//	/// The class type of the ObjectViewController to be displayed in this NSCollectionView
//	
//	private let cellType:Cell.Type
//
//	/// The UIState contains the thumbnailScale
//	
//	private var uiState:UIState
//	
//	
////----------------------------------------------------------------------------------------------------------------------
//
//
//	/// Creates ObjectCollectionView with the specified Container and cell type
//	
//	public init(container:Container?, cellType:Cell.Type, uiState:UIState)
//	{
//		self.container = container
//		self.cellType = cellType
//		self.uiState = uiState
//	}
//	
//	/// Builds a view hierarchy with a NSScrollView and a NSCollectionView inside
//	
//	public func makeNSView(context:Context) -> NSScrollView
//	{
//		let collectionView = QuicklookCollectionView(frame:.zero)
// 		
//		// Configure layout
//		
//		self.registerCellType(for:collectionView)
//        let (layout,_) = self.createLayout(for:collectionView)
//        collectionView.collectionViewLayout = layout
//        
//        // Configure selection handling
//        
//		collectionView.isSelectable = true
//		collectionView.allowsEmptySelection = true
//		collectionView.allowsMultipleSelection = true
//		
//		// Configure data source
//		
//		self.configureDataSource(for:collectionView, coordinator:context.coordinator)
//		
//		// Configure drag & drop
//		
//		collectionView.delegate = context.coordinator
//        collectionView.setDraggingSourceOperationMask([.copy], forLocal:true)
//        collectionView.setDraggingSourceOperationMask([.copy], forLocal:false)
//		FolderDropDestination.registerDragTypes(for:collectionView)
//		
//		// Wrap in a NSScrollView
//		
//		let scrollView = NSScrollView(frame:.zero)
//		scrollView.documentView = collectionView
//		scrollView.borderType = .noBorder
//		scrollView.hasVerticalScroller = true
//		scrollView.contentView.drawsBackground = false
//		scrollView.drawsBackground = false
//		scrollView.backgroundColor = .clear
//
//		return scrollView
//	}
//	
//	
//	// The selected Container has changed, pass it on to the Coordinator
//	
//	public func updateNSView(_ scrollView:NSScrollView, context:Context)
//	{
//		guard let collectionView = scrollView.documentView as? QuicklookCollectionView else { return }
//		
//		self.registerCellType(for:collectionView)
//
//		context.coordinator.uiState = self.uiState
//
//		context.coordinator.updateLayoutHandler =
//		{
//			let pos = self.saveScrollPos(for:collectionView)
//			defer { self.restoreScrollPos(for:collectionView, with:pos) }
//			
//			let (layout,columns) = self.createLayout(for:collectionView)
//			let needsAnimation = false //context.coordinator.columnCount != columns
//			context.coordinator.columnCount = columns
//			
//			if needsAnimation
//			{
//				collectionView.animator().collectionViewLayout = layout
//			}
//			else
//			{
//				collectionView.collectionViewLayout = layout
//			}
//		}
//		
//		context.coordinator.updateLayoutHandler?()
//		context.coordinator.cellType = self.cellType
//		
//		// Setting the Container triggers reload of NSCollectionView of the datasource, so this must be done last
//		
//		context.coordinator.container = self.container
//		
//	}
//	
//	/// Creates the Coordinator which provides persistant state to this view
//	
//	public func makeCoordinator() -> Coordinator
//    {
//		return Coordinator(container:container, cellType:cellType, uiState:uiState)
//    }
//}
//
//
////----------------------------------------------------------------------------------------------------------------------
//
//
//// MARK: - Setup
//	
//extension ObjectCollectionView
//{
//	/// Creates a NSCollectionViewCompositionalLayout that looks similar to regular flow layout
//	
//    private func createLayout(for collectionView:NSCollectionView) -> (NSCollectionViewLayout,Int)
//    {
//		let w:CGFloat = cellType.width
//		let h:CGFloat = cellType.height
//		let d:CGFloat = cellType.spacing
//		let ratio = w / h
//		
//		let rowWidth = max(1.0, collectionView.bounds.width - d)
//		let scale = self.uiState.thumbnailScale
//		
//		// Item (cell)
//		
//		let cellWidth = (scale * rowWidth - d).clipped(to:1.0...rowWidth)
//		let cellHeight = cellWidth / ratio
//		let width:NSCollectionLayoutDimension = w>0 ? .absolute(cellWidth) : .fractionalWidth(1.0)
//		let height:NSCollectionLayoutDimension = w>0 ? .absolute(cellHeight) : .absolute(h)
//		let itemSize = NSCollectionLayoutSize(widthDimension:width, heightDimension:height)
//        let item = NSCollectionLayoutItem(layoutSize:itemSize)
//
//		// Group (row)
//		
//        let groupSize = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1.0), heightDimension:height)
//        let group = NSCollectionLayoutGroup.horizontal(layoutSize:groupSize, subitems:[item])
//		group.interItemSpacing = .fixed(d)
//		
//		// Section
//		
//        let section = NSCollectionLayoutSection(group:group)
//        section.contentInsets = NSDirectionalEdgeInsets(top:d, leading:d, bottom:d, trailing:d)
//        section.interGroupSpacing = d
//        
//        // View
//        
//        let layout = NSCollectionViewCompositionalLayout(section:section)
//		let columns = Int(rowWidth / (cellWidth+d))
//		return (layout,columns)
//    }
//
//
//	/// Creates a NSCollectionViewDiffableDataSource. The Coordinator will is the owner of the datasource,
//	/// since it also has access to the data model.
//	
//    @MainActor private func configureDataSource(for collectionView:NSCollectionView, coordinator:Coordinator)
//    {
//		// Setup the cell provider for the dataSource
//		
//        coordinator.dataSource = NSCollectionViewDiffableDataSource<Int,Object>(collectionView:collectionView)
//        {
//			[weak coordinator] (collectionView:NSCollectionView, indexPath:IndexPath, identifier:Object) -> NSCollectionViewItem? in
//			return coordinator?.cell(for:collectionView, indexPath:indexPath, identifier:identifier)
//		}
//
//        // Set initial data
//        
//        var snapshot = NSDiffableDataSourceSnapshot<Int,Object>()
//        snapshot.appendSections([0])
//        snapshot.appendItems([], toSection:0)
//        coordinator.dataSource.apply(snapshot, animatingDifferences:false)
//    }
//    
//    /// Register the NSViewController class for the current cellType identifier
//	
//    private func registerCellType(for collectionView:NSCollectionView)
//    {
//		let identifier = self.cellType.identifier
//        collectionView.register(self.cellType, forItemWithIdentifier:identifier)
//    }
//}
//
//
////----------------------------------------------------------------------------------------------------------------------
//
//
//// MARK: - Scrolling
//
//extension ObjectCollectionView
//{
//    /// Saves the current scroll position, returning a tuple with the current bounds and visibleRect
//	
//    func saveScrollPos(for collectionView:NSCollectionView) -> (CGRect,CGRect)
//    {
//		let bounds = collectionView.bounds
//		let visible = collectionView.visibleRect
//		return (bounds,visible)
//    }
//    
//    
//    /// Restores the scroll position with the tuple of the old bounds and visibleRect.
//	///
//	/// This function tries to keep the visible cells centered, while the thumbnail scale is changing.
//	
//    func restoreScrollPos(for collectionView:NSCollectionView, with old:(CGRect,CGRect))
//    {
//		let oldBounds = old.0
//		let oldVisible = old.1
//		let oldY = oldVisible.midY
//		let oldH = oldBounds.height
//		guard oldH > 0.0 else { return }
//
//		let fraction = (oldY - oldBounds.minY) / oldH
//		let newBounds = collectionView.bounds
//		var newVisible = collectionView.visibleRect
//		let newY = newBounds.minY + fraction * newBounds.height
//		newVisible.origin.y = newY - 0.5 * newVisible.height
//		
//		collectionView.scroll(newVisible.origin)
//    }
//}
//
//
//extension NSCollectionView
//{
//	/// This notification is sent when Objects are selected
//		
//	public static let didSelectObjects = NSNotification.Name("NSCollectionView.didSelectObjects")
//
//	/// This notification is sent when the user scrolls down to the bottom
//		
//	public static let didScrollToEnd = NSNotification.Name("NSCollectionView.didScrollToEnd")
//}
//
//
////----------------------------------------------------------------------------------------------------------------------
//
//
//// MARK: - Coordinator
//	
//extension ObjectCollectionView
//{
//	public class Coordinator : NSObject, NSCollectionViewDelegate
//    {
//		/// The Container is the data model for the NSCollectionView
//		
//		@MainActor var container:Container? = nil
//		{
//			didSet
//			{
//				self.shouldAnimate = false
//				self.updateDataSource()
//			}
//		}
//		
//		/// The class type of the Object cell to be displayed in this NSCollectionView
//	
//		@MainActor var cellType:Cell.Type
//
//		/// The UIState is resposible for thumbnailScale
//		
//		@MainActor var uiState:UIState
//		{
//			didSet
//			{
//				self.updateLayout()
//			}
//		}
//
//		/// This handler is called when the layout needs to be recalculated
//		
//		@MainActor var updateLayoutHandler:(()->Void)? = nil
//
//		/// The dataSource accesses the Objects of the Container
//		
//		var dataSource: NSCollectionViewDiffableDataSource<Int,Object>! = nil
//		
//		/// The number of cells that fit inside a single row
//		
//		var columnCount = 0
//		
//		/// Set this property to true if data model changes should be animated in the view (e.g. objects inserted or deleted)
//		
//		private var shouldAnimate = false
//		
//		/// References to internal subscriptions
//		
//		private var layoutObserver:Any? = nil
//		private var dataSourceObserver:Any? = nil
//		
//		
////----------------------------------------------------------------------------------------------------------------------
//
//
// 		// MARK: - Setup
// 		
// 		
//        init(container:Container?, cellType:Cell.Type, uiState:UIState)
//        {
//			self.container = container
//			self.cellType = cellType
//			self.uiState = uiState
//			
//			super.init()
//        }
//
//		@MainActor func updateLayout()
//		{
//			self.layoutObserver = uiState.$thumbnailScale
//				.throttle(for:0.02, scheduler:DispatchQueue.main, latest:true)
//				.sink
//				{
//					[weak self] _ in
//					self?.shouldAnimate = true
//					self?.updateLayoutHandler?()
//				}
//		}
//
//
////----------------------------------------------------------------------------------------------------------------------
//
//
// 		// MARK: - Data Source
// 		
//		/// Updates the dataSource when the data model has been changed
//		
//		@MainActor func updateDataSource()
//		{
//			if let container = self.container
//			{
//				self.dataSourceObserver = container.$objects
//					.debounce(for:0.05, scheduler:DispatchQueue.main)
//					.sink
//					{
//						[weak self] objects in
//						self?.shouldAnimate = objects.count <= 1000
//						self?._updateDataSource()
//					}
//			}
//			
//			self._updateDataSource()
//		}
//		
//		/// Updates the dataSource when the data model has been changed
//		
//		@MainActor func _updateDataSource()
//		{
//			let objects = self.container?.objects ?? []
//			
//			var snapshot = NSDiffableDataSourceSnapshot<Int,Object>()
//			snapshot.appendSections([0])
//			snapshot.appendItems(objects, toSection:0)
//			
//			self.dataSource.apply(snapshot, animatingDifferences:shouldAnimate)
//		}
//
//
//		/// Returns a cell for the specified Object
//		
//		@MainActor func cell(for collectionView:NSCollectionView, indexPath:IndexPath, identifier:Object) -> NSCollectionViewItem?
//		{
//			// Get the object - Please note that the dataSource use Object directly, because it is Hashable and Equatable
//			
//			let object = identifier
//			
//			// Reuse (or create) a cell
//			
//			let item = collectionView.makeItem(withIdentifier:cellType.identifier, for:indexPath)
//			
//			// Configure the cell with the model object
//			
//			if let cell = item as? ObjectViewController
//			{
//				cell.object = object
//			}
//
//        	return item
//		}
//		
//		
//		// Once the user scrolls down near the bottom of the ObjectCollectionView, then send out a notification that
//		// can trigger certain actions (like reloading the Container).
//		
//		@MainActor public func collectionView(_ collectionView:NSCollectionView, willDisplay item:NSCollectionViewItem, forRepresentedObjectAt indexPath:IndexPath)
//		{
//			let n = self.container?.objects.count ?? 0
//			let i = indexPath.item
////			let j = (n - 20).clipped(to:0 ... n-1)
//			let j = (n - 1).clipped(to:0 ... n-1)
//			
//			if i == j
//			{
//				NotificationCenter.default.post(name:NSCollectionView.didScrollToEnd, object:self.container)
//			}
//		}
//
//
//		// Only allow seleting enabled Objects
//		
//    	@MainActor public func collectionView(_ collectionView:NSCollectionView, shouldSelectItemsAt indexPaths:Set<IndexPath>) -> Set<IndexPath>
//    	{
//			var allowedPaths = Set<IndexPath>()
//			
//			for indexPath in indexPaths
//			{
//				guard let object = self.object(for:indexPath) else { continue }
//				guard object.isEnabled else { continue }
//				allowedPaths.insert(indexPath)
//			}
//			
//			return allowedPaths
//    	}
//    	
//    	
//		// When the selection was changed, update the Quicklook preview panel and notify others
//		
//		@MainActor public func collectionView(_ collectionView:NSCollectionView, didSelectItemsAt indexPaths:Set<IndexPath>)
//		{
//			self.updatePreviewPanel()
//			self.sendDidSelectObjectsNotification(for:collectionView)
//		}
//		
//		
//		// Unfortunately the deselect gets called before the select, so we have to delay and check again
//		// if we got a new selection, before sending any notifications that announces the delesecting.
//		
//		@MainActor public func collectionView(_ collectionView:NSCollectionView, didDeselectItemsAt indexPaths:Set<IndexPath>)
//		{
//			DispatchQueue.main.async
//			{
//				if collectionView.selectionIndexPaths.isEmpty
//				{
//					self.updatePreviewPanel()
//					self.sendDidSelectObjectsNotification(for:collectionView)
//				}
//			}
//		}
//		
//		
//		// After changing the selection, the QLPreviewPanel should be updated (if currently open)
//		
//		func updatePreviewPanel()
//		{
//			if let panel = QLPreviewPanel.shared(), panel.isVisible
//			{
//				panel.reloadData()
//			}
//		}
//		
//		
//		/// Sends a notification announcing which Objects have been selected
//		
//		func sendDidSelectObjectsNotification(for collectionView:NSCollectionView)
//		{
//			let objects = collectionView.selectionIndexPaths
//				.compactMap { collectionView.item(at:$0) as? ObjectViewController }
//				.compactMap { $0.object }
//			
//			if objects.isEmpty
//			{
//				NotificationCenter.default.post(name: NSCollectionView.didSelectObjects, object:nil)
//			}
//			else
//			{
//				NotificationCenter.default.post(name: NSCollectionView.didSelectObjects, object:objects)
//			}
//		}
//		
//		
////----------------------------------------------------------------------------------------------------------------------
//
//
//		// MARK: - Dragging Source
//
//		// Allow dragging of cells to other destinations
//		
//		@MainActor public func collectionView(_ collectionView:NSCollectionView, canDragItemsAt indexPaths:Set<IndexPath>, with event:NSEvent) -> Bool
//		{
//			return true
//		}
//		
//		
//		// Start dragging the Object. Since the Object can be remote, a NSFilePromiseProvider will be returned. The download will be triggered,
//		// once the NSFilePromiseProvider is received at the drop destination. Obviously the download is skipped if the Object already points
//		// to local file.
//		
//		@MainActor public func collectionView(_ collectionView:NSCollectionView, pasteboardWriterForItemAt indexPath:IndexPath) -> NSPasteboardWriting?
//		{
//			// Get Object to be dragged
//			
//			guard let object = self.object(for:indexPath) else { return nil }
//			guard object.isEnabled else { return nil }
//			
//			// Get a file promise from the Object
//			
//			guard object.isLocallyAvailable || object.isDownloadable else { return nil }
//			return object.filePromiseProvider
//		}
//		
//		
//		// Prevent item from being hidden (creating a hole in the grid) while being dragged
//
//		@MainActor public func collectionView(_ collectionView:NSCollectionView, draggingSession session:NSDraggingSession, willBeginAt screenPoint:NSPoint, forItemsAt indexPaths:Set<IndexPath>)
//		{
//			for indexPath in indexPaths
//			{
//				collectionView.item(at:indexPath)?.view.isHidden = false
//			}
//		}
//
//		/// Returns the Object for the specified IndexPath
//		
//		@MainActor func object(for indexPath:IndexPath) -> Object?
//		{
//			let i = indexPath.item
//			guard let objects = self.container?.objects else { return nil }
//			guard i < objects.count else { return nil }
//			return objects[i]
//		}
//
//
////----------------------------------------------------------------------------------------------------------------------
//
//
// 		// MARK: - Dragging Destination
//
//		// Check if the collectionView can receive the dragged files
//		
//		@MainActor public func collectionView(_ collectionView:NSCollectionView, validateDrop draggingInfo:NSDraggingInfo, proposedIndexPath:AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation:UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation
//		{
//			return self.container?.fileDropDestination?.collectionView(collectionView, validateDrop:draggingInfo, proposedIndexPath:proposedIndexPath, dropOperation:proposedDropOperation) ?? []
//		}
//
//
//		// Copy the dragged files to the Container
//		
//		@MainActor public func collectionView(_ collectionView:NSCollectionView, acceptDrop draggingInfo:NSDraggingInfo, indexPath:IndexPath, dropOperation:NSCollectionView.DropOperation) -> Bool
//		{
//			return self.container?.fileDropDestination?.collectionView(collectionView, acceptDrop:draggingInfo, indexPath:indexPath, dropOperation:dropOperation) ?? false
//		}
//
//	}
//}
//
//
////----------------------------------------------------------------------------------------------------------------------


#endif

