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


public struct LightroomCCFilterBar : View
{
	// Model
	
	@ObservedObject var selectedContainer:Container
	@ObservedObject var filter:LightroomCCFilter
	
	// Init
	
	public init(with selectedContainer:Container, filter:LightroomCCFilter)
	{
		self.selectedContainer = selectedContainer
		self.filter = filter
	}
	
	// View
	
	public var body: some View
    {
		HStack
		{
			// Search field
			
			TextField(searchPlaceholder, text:self.$filter.searchString)
				.frame(maxWidth:300)
				.textFieldStyle(RoundedBorderTextFieldStyle())

			RatingFilterView(rating:self.$filter.rating)
				
			Spacer()

			// Sort order
			
			SortOrderPopup(
				defaultShapeIcon:"square.grid.2x2",
				selectedContainer:selectedContainer,
				filter:filter)
		}
		.padding(.horizontal,20)
		.padding(.vertical,10)
    }
 }


//----------------------------------------------------------------------------------------------------------------------


extension LightroomCCFilterBar
{
    var searchPlaceholder:String
    {
		NSLocalizedString("Search", bundle:.BXMediaBrowser, comment:"Placeholder")
    }
    
    var sortByLabel:String
    {
		NSLocalizedString("Sort by:", bundle:.BXMediaBrowser, comment:"Label")
    }
    
    var directionIcon:String
    {
		filter.sortDirection == .ascending ? "chevron.up" : "chevron.down"
    }
}


//----------------------------------------------------------------------------------------------------------------------
