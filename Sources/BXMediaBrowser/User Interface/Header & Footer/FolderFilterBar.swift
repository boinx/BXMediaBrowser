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
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct FolderFilterBar : View
{
	// Model
	
	@ObservedObject var selectedContainer:Container
	@ObservedObject var filter:FolderFilter
	
	// Init
	
	public init(with selectedContainer:Container, filter:FolderFilter)
	{
		self.selectedContainer = selectedContainer
		self.filter = filter
	}
	
	// View
	
	public var body: some View
    {
		HStack(spacing:10)
		{
			NativeSearchField(value:self.$filter.searchString, placeholderString:searchPlaceholder)
				.strokeBorder()
				.frame(maxWidth:300)
				.id(selectedContainer.identifier)
				
			Spacer()

			RatingFilterView(rating:self.$filter.rating)
				.padding(.leading,-12)
				
			SortOrderPopup(
				defaultShapeIcon:defaultShapeIcon,
				selectedContainer:selectedContainer,
				filter:filter)
		}
		.padding(.horizontal,20)
		.padding(.vertical,10)
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension FolderFilterBar
{
	var defaultShapeIcon:String
	{
		let isAudio = selectedContainer.mediaTypes.contains(.audio)
		return isAudio ? "text.justify" : "square.grid.2x2"
	}
	
    var searchPlaceholder:String
    {
		NSLocalizedString("Search", bundle:.BXMediaBrowser, comment:"Placeholder")
    }
}


//----------------------------------------------------------------------------------------------------------------------
