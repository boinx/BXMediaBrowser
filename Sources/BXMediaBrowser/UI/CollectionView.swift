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
//		scrollView.drawsBackground = false
		context.coordinator.container = self.container
	}
	

	public func makeCoordinator() -> Coordinator
    {
        return Coordinator(container:container)
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
extension CollectionView
{
    private func createLayout() -> NSCollectionViewLayout
    {
		let w:CGFloat = ImageCell.width
		let h:CGFloat = ImageCell.height
		let d:CGFloat = ImageCell.spacing

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


    private func configureDataSource(for collectionView:NSCollectionView, coordinator:Coordinator)
    {
        coordinator.dataSource = NSCollectionViewDiffableDataSource<Int,Object>(collectionView:collectionView)
        {
			(collectionView:NSCollectionView, indexPath:IndexPath, identifier:Object) -> NSCollectionViewItem? in

			let item = collectionView.makeItem(withIdentifier:ImageCell.identifier, for:indexPath)
			let object = identifier
			
			if let cell = item as? ImageCell
			{
				cell.object = object
			}

        	return item
        }

        // initial data
        
        var snapshot = NSDiffableDataSourceSnapshot<Int,Object>()
        snapshot.appendSections([0])
        snapshot.appendItems([])
        coordinator.dataSource.apply(snapshot, animatingDifferences:false)
    }
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
extension CollectionView
{
	public class Coordinator : NSObject, NSCollectionViewDelegate
    {
		@MainActor var container:Container? = nil
		{
			didSet { self.updateDataSource() }
		}
		
		var dataSource: NSCollectionViewDiffableDataSource<Int,Object>! = nil
		
		private var observers:[Any] = []
		
		
        init(container:Container?)
        {
			self.container = container
        }
		
		
		@MainActor func updateDataSource()
		{
			self.observers = []
			
			if let container = self.container
			{
				self.observers += container.$objects.sink
				{
					_ in
					DispatchQueue.main.async { self._updateDataSource() }
				}
			}
			
			self._updateDataSource()
		}
		
		
		@MainActor func _updateDataSource()
		{
			let objects = self.container?.objects ?? []
			var snapshot = NSDiffableDataSourceSnapshot<Int,Object>()

			snapshot.appendSections([0])
			snapshot.appendItems(objects)
			self.dataSource.apply(snapshot, animatingDifferences:true)
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



/*

class GridWindowController: NSWindowController
{
    private var dataSource: NSCollectionViewDiffableDataSource<Section, Int>! = nil
    @IBOutlet weak var collectionView: NSCollectionView!

    enum Section
    {
        case main
    }

    override func windowDidLoad()
    {
        super.windowDidLoad()
        configureHierarchy()
        configureDataSource()
    }

    private func configureHierarchy()
    {
        let itemNib = NSNib(nibNamed: "TextItem", bundle: nil)
        collectionView.register(itemNib, forItemWithIdentifier: TextItem.identifier)
        collectionView.collectionViewLayout = createLayout()
    }
    
    private func createLayout() -> NSCollectionViewLayout
    {
        let itemSize = NSCollectionLayoutSize(
			widthDimension: .absolute(120),
			heightDimension: .absolute(80))
		
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

		let padding:CGFloat = 5
		
        item.contentInsets = NSDirectionalEdgeInsets(
			top:padding,
			leading:padding,
			bottom:padding,
			trailing:padding)

        let groupSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(80))
            
        let group = NSCollectionLayoutGroup.horizontal(layoutSize:groupSize, subitems:[item])

        let section = NSCollectionLayoutSection(group:group)
        let layout = NSCollectionViewCompositionalLayout(section:section)
        return layout
    }

    private func configureDataSource()
    {
        dataSource = NSCollectionViewDiffableDataSource<Section,Int>(collectionView: collectionView, itemProvider:
        {
			(collectionView:NSCollectionView, indexPath:IndexPath, identifier:Int) -> NSCollectionViewItem? in
            let item = collectionView.makeItem(withIdentifier:TextItem.reuseIdentifier, for:indexPath)
            item.textField?.stringValue = "\(identifier)"
            return item
        })

        // initial data
        
        var snapshot = NSDiffableDataSourceSnapshot<Section,Int>()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(Array(0..<94))
        dataSource.apply(snapshot, animatingDifferences:false)
    }
}


*/
