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
	//	   NSClipView
	//	     NSCollectionView
	
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
		context.coordinator.container = self.container
	}
	
	/// Creates the Coordinator which provides persistant state to this view
	
	public func makeCoordinator() -> Coordinator
    {
        return Coordinator(container:container)
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
extension CollectionView
{
	/// Creates a NSCollectionViewCompositionalLayout that looks similar to regular flow layout
	
    private func createLayout() -> NSCollectionViewLayout
    {
		let w:CGFloat = ImageThumbnailCell.width
		let h:CGFloat = ImageThumbnailCell.height
		let d:CGFloat = ImageThumbnailCell.spacing

        let itemSize = NSCollectionLayoutSize(widthDimension:.absolute(w), heightDimension:.absolute(h))
        let item = NSCollectionLayoutItem(layoutSize:itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1.0), heightDimension:.absolute(h))
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
			didSet { self.updateDataSource() }
		}
		
		/// The dataSource accesses the Objects of the Container
		
		var dataSource: NSCollectionViewDiffableDataSource<Int,Object>! = nil
		
		/// References to internal subscriptions
		
		private var observers:[Any] = []
		
		/// Creates a Coordinator
		
        init(container:Container?)
        {
			self.container = container
        }
		
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
						[weak self] _ in self?._updateDataSource()
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
			
			self.dataSource.apply(snapshot, animatingDifferences:true)
		}


		/// Returns a cell for the specified Object
		
		@MainActor func cell(for collectionView:NSCollectionView, indexPath:IndexPath, identifier:Object) -> NSCollectionViewItem?
		{
			// Get the object - Please note that the dataSource use Object directly, because it is Hashable and Equatable
			
			let object = identifier
			
			// Reuse (or create) a cell
			
			let item = collectionView.makeItem(withIdentifier:ImageThumbnailCell.identifier, for:indexPath)
			
			// Configure the cell with the model object
			
			if let cell = item as? ImageThumbnailCell
			{
				cell.object = object
			}

        	return item
		}
		
		
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
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif

