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


//----------------------------------------------------------------------------------------------------------------------


class BXCollectionView : QuicklookCollectionView
{
	public var willSetFrameSizeHandler:((NSSize)->Void)? = nil
	
	override open func setFrameSize(_ newSize:NSSize)
	{
//		self.collectionViewLayout = nil
		self.willSetFrameSizeHandler?(newSize)

		super.setFrameSize(newSize)
	}
	
	override open func layout()
	{
		super.layout()
	}
	

//	/// Creates a NSCollectionViewCompositionalLayout that looks similar to regular flow layout
//
//	public func updateLayout(_cellWidth:CGFloat?, _cellHeight:CGFloat, _spacing:CGFloat, viewSize:CGSize? = nil)
//	{
//		let viewWidth = viewSize?.width ?? self.bounds.width
//
//		let w:CGFloat = cellType.width
//		let h:CGFloat = cellType.height
//		let d:CGFloat = spacing
//		let ratio = w / h
//
//		let minWidth:CGFloat = 70 // This is the minimum width to display ObjectRatingView without clipping
//		let maxWidth = max(minWidth, viewWidth-4*d)
//		let size = self.uiState.thumbnailSize
//
//		// Item (cell)
//
//		let cellWidth = size.clipped(to:minWidth...maxWidth)
//		let cellHeight = cellWidth / ratio
//
//		var itemWidth:NSCollectionLayoutDimension = .absolute(cellWidth)
//		var itemHeight:NSCollectionLayoutDimension = .absolute(cellHeight)
//        var item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension:itemWidth, heightDimension:itemHeight))
//
//		if w == 0	// Use full view width and hard-coded height as specified (used for AudioObjectCells)
//		{
//			itemWidth = .fractionalWidth(1.0)
//			itemHeight = .absolute(h)
//			item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension:itemWidth, heightDimension:itemHeight))
//		}
////		else if cellWidth >= maxWidth-10 || viewWidth < minWidth
////		{
////			itemWidth = .fractionalWidth(1.0)
////			itemHeight = .fractionalWidth(1.0/ratio)
////			item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension:itemWidth, heightDimension:itemHeight))
////		}
//
//		// Group (row)
//
//        let groupSize = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1.0), heightDimension:itemHeight)
// 		let group = NSCollectionLayoutGroup.horizontal(layoutSize:groupSize, subitems:[item])
////		let count = Int((availableWidth+d) / (cellWidth+d))
////        let group = NSCollectionLayoutGroup.horizontal(layoutSize:groupSize, subitem:item, count:16)	// Fix for crash #2818747896u was suggested at https://stackoverflow.com/questions/63748268/uicollectionviewdiffabledatasource-crash-invalid-parameter-not-satisfying-item
//		group.interItemSpacing = .fixed(d)
//		group.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading:.flexible(0), top:nil, trailing:.flexible(0), bottom:nil)
//
//		// Section
//
//        let section = NSCollectionLayoutSection(group:group)
//        section.interGroupSpacing = d
//        section.contentInsets = NSDirectionalEdgeInsets(top:d, leading:d, bottom:d, trailing:d)
//
//        // View
//
//        let layout = NSCollectionViewCompositionalLayout(section:section)
////		let columns = Int((maxWidth+d) / (cellWidth+d))
////		return (layout,columns)
//		return layout
//    }
}


//----------------------------------------------------------------------------------------------------------------------


#endif
