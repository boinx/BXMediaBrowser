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


import BXSwiftUI
import BXSwiftUtils
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct SortOrderPopup : View
{
	// Model
	
	var defaultShapeIcon = "square.grid.2x2"
	
	@ObservedObject var selectedContainer:Container
	@ObservedObject var filter:Object.Filter
	
	// View
	
	public var body: some View
    {
		if selectedContainer.allowedSortTypes.isEmpty
		{
			EmptyView()
		}
		else
		{
			HStack(spacing:0)
			{
				BXImage(systemName:shapeIcon)
				BXImage(systemName:arrowIcon).scaleEffect(0.75)
			}
			.id(selectedContainer.identifier)
			.popupMenu(sortOrderItems)
		}
    }
    
    var shapeIcon:String
    {
		switch filter.sortType
		{
			case .captureDate: return "clock"
			case .creationDate: return "clock"
			case .duration: return "clock"
			case .alphabetical: return "character"
			case .rating: return "star"
			case .useCount: return "1.circle.fill"
			case .artist: return "person"
			case .album: return "square.stack"
			case .genre: return "guitars"

			default: return defaultShapeIcon
		}
    }
    
    var arrowIcon:String
    {
		filter.sortDirection == .ascending ? "chevron.up" : "chevron.down"
    }
    
    var sortOrderItems:[BXMenuItemSpec]
    {
		let sortBy = NSLocalizedString("Sort by", bundle:.BXMediaBrowser, comment:"Menu Item")
		let direction = NSLocalizedString("Direction", bundle:.BXMediaBrowser, comment:"Menu Item")
		let ascending = NSLocalizedString("Ascending", bundle:.BXMediaBrowser, comment:"Menu Item")
		let descending = NSLocalizedString("Descending", bundle:.BXMediaBrowser, comment:"Menu Item")

		var items:[BXMenuItemSpec] = [BXMenuItemSpec.section(title:sortBy)]
		
		items += selectedContainer.allowedSortTypes.map
		{
			sortType in
			
			BXMenuItemSpec.action(title:sortType.localizedName, state:{ self.state(for:sortType) })
			{
				filter.sortType = sortType
			}
		}
		
		items += BXMenuItemSpec.divider
		items += BXMenuItemSpec.section(title:direction)

		items += BXMenuItemSpec.action(title:ascending, state:{ self.state(for:.ascending) })
		{
			filter.sortDirection = .ascending
		}
	
		items += BXMenuItemSpec.action(title:descending, state:{ self.state(for:.descending) })
		{
			filter.sortDirection = .descending
		}
		
		return items
    }

    func state(for sortType:Object.Filter.SortType) -> NSControl.StateValue
    {
		self.filter.sortType == sortType ? .on : .off
    }
    
    func state(for sortDirection:Object.Filter.SortDirection) -> NSControl.StateValue
    {
		self.filter.sortDirection == sortDirection ? .on : .off
    }
}


//----------------------------------------------------------------------------------------------------------------------


//#if os(iOS)
//
//public struct SortOrderPopup : View
//{
//	// Model
//
//	var defaultShapeIcon = "square.grid.2x2"
//
//	@ObservedObject var selectedContainer:Container
//	@ObservedObject var filter:Object.Filter
//
//	// View
//
//	public var body: some View
//    {
//		if selectedContainer.allowedSortTypes.isEmpty
//		{
//			EmptyView()
//		}
//		else
//		{
//			if #available(iOS 14, *)
//			{
//				Menu( content:
//				{
//					ForEach(selectedContainer.allowedSortTypes, id:\.self)
//					{
//						self.button(for:$0)
//					}
//
//					self.button(for:.ascending)
//					self.button(for:.descending)
//				},
//				label:
//				{
//					HStack(spacing:0)
//					{
//						BXImage(systemName:shapeIcon)
//						BXImage(systemName:arrowIcon).scaleEffect(0.75)
//					}
//				})
//
//				.id(selectedContainer.identifier)
//			}
//
//		}
//    }
//
//    var shapeIcon:String
//    {
//		switch filter.sortType
//		{
//			case .captureDate: return "clock"
//			case .creationDate: return "clock"
//			case .duration: return "clock"
//			case .alphabetical: return "character"
//			case .rating: return "star"
//			case .artist: return "person"
//			case .album: return "square.stack"
//			case .genre: return "guitars"
//
//			default: return defaultShapeIcon
//		}
//    }
//
//    var arrowIcon:String
//    {
//		filter.sortDirection == .ascending ? "chevron.up" : "chevron.down"
//    }
//
//    func button(for sortType:Object.Filter.SortType) -> some View
//    {
//		Button
//		{
//			filter.sortType = sortType
//		}
//		label:
//		{
//			HStack
//			{
//				Text(icon(for:sortType))
//				Text(sortType.localizedName)
//			}
//		}
//    }
//
//	func button(for sortDirection:Object.Filter.SortDirection) -> some View
//    {
//		HStack
//		{
//			Text(icon(for:sortDirection))
//
//			if sortDirection == .ascending
//			{
//				Text(NSLocalizedString("Ascending", bundle:.BXMediaBrowser, comment:"Menu Item"))
//			}
//			else
//			{
//				Text(NSLocalizedString("Descending", bundle:.BXMediaBrowser, comment:"Menu Item"))
//			}
//		}
//    }
//
//	func icon(for sortType:Object.Filter.SortType) -> String
//    {
//		self.filter.sortType == sortType ? "✓" : " "
//    }
//
//    func icon(for sortDirection:Object.Filter.SortDirection) -> String
//    {
//		self.filter.sortDirection == sortDirection ? "✓" : " "
//    }
//}
//
//#endif


//----------------------------------------------------------------------------------------------------------------------
