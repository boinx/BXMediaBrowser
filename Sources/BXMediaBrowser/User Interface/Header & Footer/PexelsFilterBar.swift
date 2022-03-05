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
	
	var pexelsContainer:PexelsContainer?
	{
		selectedContainer as? PexelsContainer
	}
	
	var saveHandler:PexelsContainer.SaveContainerHandler?
	{
		self.pexelsContainer?.saveHandler
	}
	
	var isSaveEnabled:Bool
	{
		!self.searchString.isEmpty
	}
	
	var description:String
	{
		self.pexelsContainer?.description ?? ""
	}
	
	// View
	
	public var body: some View
    {
		HStack
		{
			if let container = self.pexelsContainer, let saveHandler = self.saveHandler
			{
				TextField(searchPlaceholder, text:self.$searchString)
				{
					self.filter.searchString = self.searchString
				}
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.frame(maxWidth:300)
				
				PexelsOrientationView(filter:filter)
				PexelsColorView(filter:filter)
				
				RatingFilterView(rating:self.$filter.rating)

				Spacer()
				
				Button(saveTitle)
				{
					saveHandler(container)
				}
				.disabled(!isSaveEnabled)
			}
			else
			{
				Text(description)
					.centerAligned()
					.frame(height:20)
			}
			
		}
		.padding(.horizontal,20)
		.padding(.vertical,10)
    }

    var searchPlaceholder:String
    {
		NSLocalizedString("Search", bundle:.BXMediaBrowser, comment:"Placeholder")
    }
    
    var saveTitle:String
    {
		NSLocalizedString("Save", bundle:.BXMediaBrowser, comment:"Button Title")
    }
    
}


//----------------------------------------------------------------------------------------------------------------------


struct PexelsOrientationView : View
{
	@ObservedObject var filter:PexelsFilter
	
	var body: some View
	{
		MenuButton(self.filter.orientation.localizedName)
		{
			ForEach(PexelsFilter.Orientation.allCases, id:\.self)
			{
				value in
				
				Button(value.localizedName)
				{
					self.filter.orientation = value
				}
			}
		}
		.fixedSize()
	}
}


//----------------------------------------------------------------------------------------------------------------------


struct PexelsColorView : View
{
	@ObservedObject var filter:PexelsFilter
	
	var body: some View
	{
		MenuButton(self.filter.color.localizedName)
		{
			ForEach(PexelsFilter.Color.allCases, id:\.self)
			{
				color in
				
				Button(action:{ self.filter.color = color })
				{
					Text(color.localizedName)
				}
			}
		}
		.fixedSize()
	}
}


//----------------------------------------------------------------------------------------------------------------------
