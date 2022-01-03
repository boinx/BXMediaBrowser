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


/// This view displays a single Section within a LibaryView

public struct BXCollectionView : NSViewRepresentable
{
	public typealias NSViewType = NSCollectionView
	
	private var container:Container?
	
	public init(container:Container?)
	{
		self.container = container
	}
	
	public func makeNSView(context:Context) -> NSCollectionView
	{
		let view = NSCollectionView(frame:CGRect(x:0, y:0, width:1000, height:1000))
		
		let bundle = Bundle.module //BXMediaBrowser
        let nib = NSNib(nibNamed:"ImageCell", bundle:bundle)
        view.register(nib, forItemWithIdentifier: ImageCell.reuseIdentifier)
//        view.register(ImageCell.self, forItemWithIdentifier:ImageCell.reuseIdentifier)

        view.collectionViewLayout = self.createLayout()

		self.configureDataSource(for:view, coordinator:context.coordinator)
		
		view.isSelectable = true
		view.allowsEmptySelection = true
		view.allowsMultipleSelection = true
		
		return view
	}
	
	
	public func updateNSView(_ collectionView:NSCollectionView, context:Context)
	{
		context.coordinator.container = self.container
	}
	
	
    private func createLayout() -> NSCollectionViewLayout
    {
print("\(Self.self).\(#function)")

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


    private func configureDataSource(for collectionView:NSCollectionView, coordinator:Coordinator)
    {
print("\(Self.self).\(#function)")

        coordinator.dataSource = NSCollectionViewDiffableDataSource<Int,Object>(collectionView:collectionView)
        {
			(collectionView:NSCollectionView, indexPath:IndexPath, identifier:Object) -> NSCollectionViewItem? in

			let item = collectionView.makeItem(withIdentifier:ImageCell.reuseIdentifier, for:indexPath)
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

	public func makeCoordinator() -> Coordinator
    {
        return Coordinator(container:container)
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension BXCollectionView
{
	public class Coordinator : NSObject
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
print("\(Self.self).\(#function)")

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
        collectionView.register(itemNib, forItemWithIdentifier: TextItem.reuseIdentifier)
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
