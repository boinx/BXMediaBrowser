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

import SwiftUI
import AppKit


//----------------------------------------------------------------------------------------------------------------------


/// This subclass of NSCollectionView can display the Objects of a Container

public struct CollectionView<Cell:ObjectCell> : NSViewRepresentable
{
	// This NSViewRepresentable doesn't return a single view, but a whole hierarchy:
	//
	// 	 NSScrollView
	//	    NSClipView
	//	       NSCollectionView
	
	public typealias NSViewType = NSScrollView
	
	/// The objects of this Container are displayed in the NSCollectionView
	
	private var container:Container? = nil
	
	/// The class type of the Object cell to be displayed in this NSCollectionView
	
	private let cellType:Cell.Type
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates CollectionView with the specified Container and cell type
	
	public init(container:Container?, cellType:Cell.Type)
	{
		self.container = container
		self.cellType = cellType
	}
	
	/// Builds a view hierarchy with a NSScrollView and a NSCollectionView inside
	
	public func makeNSView(context:Context) -> NSScrollView
	{
		let collectionView = NSCollectionView(frame:.zero)
		
		// Configure layout
		
		let identifier = self.cellType.identifier
		let name = self.cellType.nibName
		let bundle = Bundle.module
        let nib = NSNib(nibNamed:name, bundle:bundle)
        
        collectionView.register(nib, forItemWithIdentifier:identifier)
        collectionView.collectionViewLayout = self.createLayout()
        
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
		FileDropDestination.registerDragTypes(for:collectionView)
		
		// Wrap in a NSScrollView
		
		let scrollView = NSScrollView(frame:.zero)
		scrollView.documentView = collectionView
		scrollView.borderType = .noBorder
		scrollView.hasVerticalScroller = true
		scrollView.contentView.drawsBackground = false
		scrollView.drawsBackground = false
		scrollView.backgroundColor = .clear

		return scrollView
	}
	
	
	// The selected Container has changed, pass it on to the Coordinator
	
	public func updateNSView(_ scrollView:NSScrollView, context:Context)
	{
		guard let collectionView = scrollView.documentView as? NSCollectionView else { return }
		collectionView.collectionViewLayout = self.createLayout()

		context.coordinator.cellType = self.cellType 	// Must update this first
		context.coordinator.container = self.container	// because this line already triggers reload of NSCollectionView
	}
	
	/// Creates the Coordinator which provides persistant state to this view
	
	public func makeCoordinator() -> Coordinator
    {
        return Coordinator(container:container, cellType:cellType)
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
extension CollectionView
{
	/// Creates a NSCollectionViewCompositionalLayout that looks similar to regular flow layout
	
    private func createLayout() -> NSCollectionViewLayout
    {
		let w:CGFloat = cellType.width
		let h:CGFloat = cellType.height
		let d:CGFloat = cellType.spacing
		let width:NSCollectionLayoutDimension = w>0 ? .absolute(w) : .fractionalWidth(1.0)
		let height:NSCollectionLayoutDimension = .absolute(h)
		
        let itemSize = NSCollectionLayoutSize(widthDimension:width, heightDimension:height)
        let item = NSCollectionLayoutItem(layoutSize:itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1.0), heightDimension:height)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize:groupSize, subitems:[item])
		group.interItemSpacing = .fixed(d)
		
        let section = NSCollectionLayoutSection(group:group)
        section.contentInsets = NSDirectionalEdgeInsets(top:d, leading:d, bottom:d, trailing:d)
        section.interGroupSpacing = d
        
        return NSCollectionViewCompositionalLayout(section:section)
    }


	/// Creates a NSCollectionViewDiffableDataSource. The Coordinator will is the owner of the datasource,
	/// since it also has access to the data model.
	
    private func configureDataSource(for collectionView:NSCollectionView, coordinator:Coordinator)
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
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
extension CollectionView
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
	
		/// The dataSource accesses the Objects of the Container
		
		var dataSource: NSCollectionViewDiffableDataSource<Int,Object>! = nil
		
		private var shouldAnimate = false
		
		/// References to internal subscriptions
		
		private var observers:[Any] = []
		
		/// Creates a Coordinator
		
        init(container:Container?, cellType:Cell.Type)
        {
			self.container = container
			self.cellType = cellType
        }
		

//----------------------------------------------------------------------------------------------------------------------


 		// MARK: - Data Source
 		
		/// Updates the dataSource when the data model has been changed
		
		@MainActor func updateDataSource()
		{
			self.observers = []
			
			if let container = self.container
			{
				self.observers += container.$objects
					.debounce(for:0.05, scheduler:RunLoop.main)
					.sink
					{
						[weak self] _ in
						self?.shouldAnimate = true
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
			
			self.dataSource.apply(snapshot, animatingDifferences:shouldAnimate)
		}


		/// Returns a cell for the specified Object
		
		@MainActor func cell(for collectionView:NSCollectionView, indexPath:IndexPath, identifier:Object) -> NSCollectionViewItem?
		{
			// Get the object - Please note that the dataSource use Object directly, because it is Hashable and Equatable
			
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
		
		
		/// Once the user scrolls down near the bottom of the CollectionView, then send out a notification that
		/// can trigger certain actions (like reloading the Container).
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, willDisplay item:NSCollectionViewItem, forRepresentedObjectAt indexPath:IndexPath)
		{
			let n = self.container?.objects.count ?? 0
			let i = indexPath.item
			let j = (n - 20).clipped(to:0 ... n-1)
			
			if i == j
			{
				NotificationCenter.default.post(name:didScrollToEndNotification, object:self.container)
			}
		}


//----------------------------------------------------------------------------------------------------------------------


		// MARK: - Dragging Source

		// Allow dragging of cells to other destinations
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, canDragItemsAt indexPaths:Set<IndexPath>, with event:NSEvent) -> Bool
		{
			return true
		}
		
		
		// Start dragging the Object. Since the Object can be remote, a NSFilePromiseProvider will be returned. The download will be triggered,
		// once the NSFilePromiseProvider is received at the drop destination. Obviously the download is skipped if the Object already points
		// to local file.
		
		@MainActor public func collectionView(_ collectionView:NSCollectionView, pasteboardWriterForItemAt indexPath:IndexPath) -> NSPasteboardWriting?
		{
			// Get Object to be dragged
			
			let i = indexPath.item
			guard let objects = self.container?.objects else { return nil }
			guard i < objects.count else { return nil }
			let object = objects[i]
			
			// Get a file promise from the Object
			
			guard object.isLocallyAvailable || object.isDownloadable else { return nil }
			return object.filePromiseProvider
		}
		
		
		//  Prevent item from being hidden (creating a hole in the grid) while being dragged

		@MainActor public func collectionView(_ collectionView:NSCollectionView, draggingSession session:NSDraggingSession, willBeginAt screenPoint:NSPoint, forItemsAt indexPaths:Set<IndexPath>)
		{
			for indexPath in indexPaths
			{
				collectionView.item(at:indexPath)?.view.isHidden = false
			}
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


public let didScrollToEndNotification = NSNotification.Name("CollectionView.didScrollToEnd")


//----------------------------------------------------------------------------------------------------------------------


#endif

