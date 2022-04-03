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


public struct PexelsFilterBar : View
{
	// Model
	
	@ObservedObject var selectedContainer:Container
	@ObservedObject var filter:PexelsFilter
	@State private var searchString:String = ""
	
	// Init
	
	public init(with selectedContainer:Container, filter:PexelsFilter)
	{
		self.selectedContainer = selectedContainer
		self.filter = filter
		self.searchString = filter.searchString
	}
	
	// Accessors
	
	var pexelsContainer:PexelsContainer?
	{
		selectedContainer as? PexelsContainer
	}
	
	var isSaveEnabled:Bool
	{
		!self.searchString.isEmpty
	}
	
	var description:String
	{
		self.pexelsContainer?.description ?? ""
	}
	
    var searchPlaceholder:String
    {
		NSLocalizedString("Search", bundle:.BXMediaBrowser, comment:"Placeholder")
    }
    
    var saveTitle:String
    {
		NSLocalizedString("Save", bundle:.BXMediaBrowser, comment:"Button Title")
    }
    
    func colorMenuItems(value:Binding<PexelsFilter.Color>) -> [BXMenuItemSpec]
    {
		PexelsFilter.Color.allCases.map
		{
			color in
			
			BXMenuItemSpec.action(icon:nil, title:color.localizedName, state: { value.wrappedValue == color ? .on : .off })
			{
				value.wrappedValue = color
			}
		}
    }
    
    func orientationMenuItems(value:Binding<PexelsFilter.Orientation>) -> [BXMenuItemSpec]
    {
		PexelsFilter.Orientation.allCases.map
		{
			orientation in
			
			BXMenuItemSpec.action(icon:nil, title:orientation.localizedName, state: { value.wrappedValue == orientation ? .on : .off })
			{
				value.wrappedValue = orientation
			}
		}
    }
    
	// View
	
	public var body: some View
    {
		HStack
		{
			if let container = self.pexelsContainer, let saveHandler = container.saveHandler
			{
				TextField(searchPlaceholder, text:self.$searchString)
				{
					self.filter.searchString = self.searchString
				}
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.frame(maxWidth:300)
				
				BXImage(systemName:filter.orientation.icon).font(.system(size:17, weight:.regular))
					.popupMenu(self.orientationMenuItems(value:self.$filter.orientation))

				ColorIconView(color:filter.color.color)
					.popupMenu(self.colorMenuItems(value:self.$filter.color))
				
				BXImage(systemName:"plus.circle")
					.font(.system(size:16, weight:.regular))
					.reducedOpacityWhenDisabled()
					.disabled(filter.searchString.isEmpty)
					.onTapGesture
					{
						saveHandler(container)
					}
					
				Spacer()
				
				RatingFilterView(rating:self.$filter.rating)
			}
			else
			{
				Text(description)
					.centerAligned()
					.frame(height:22)
			}
		}
		.padding(.horizontal,20)
		.padding(.vertical,10)
    }
}


//----------------------------------------------------------------------------------------------------------------------
