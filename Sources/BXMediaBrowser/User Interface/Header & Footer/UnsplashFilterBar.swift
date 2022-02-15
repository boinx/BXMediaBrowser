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


public struct UnsplashFilterBar : View
{
	// Model
	
	@ObservedObject var selectedContainer:Container
	@ObservedObject var filter:UnsplashFilter
	@EnvironmentObject var sortController:SortController
	@State private var searchString:String = ""
	
	// For some reason having more than one @State var crashes SwiftUI here, so we'll bundle the three needed
	// properties in a helper class called UsplashFilterData. Seems to be a functioning workaround for now.
	
//	@State private var orientation:String = ""
//	@State private var color:String = ""
//	@State private var filterData = UnsplashFilterData()
	
	// Init
	
	public init(with selectedContainer:Container, filter:UnsplashFilter)
	{
		self.selectedContainer = selectedContainer
		self.filter = filter
		self.searchString = filter.searchString
		
//		if let filter = selectedContainer.filter as? UnsplashFilter
//		{
//			self.filterData.searchString = filter.searchString
//			self.filterData.orientation = filter.orientation ?? .any
//			self.filterData.color = filter.color ?? .any
//		}
//
//		self.filterData.didChange = self.updateFilter
	}
	
	var unsplashContainer:UnsplashContainer?
	{
		selectedContainer as? UnsplashContainer
	}
	
	var saveHandler:UnsplashContainer.SaveContainerHandler?
	{
		self.unsplashContainer?.saveHandler
	}
	
	var isSaveEnabled:Bool
	{
		!self.searchString.isEmpty
	}
	
	var description:String
	{
		self.unsplashContainer?.description ?? ""
	}
	
	// View
	
	public var body: some View
    {
		HStack
		{
			if let container = self.unsplashContainer, let saveHandler = self.saveHandler
			{
				TextField("Search", text:self.$searchString)
				{
					self.filter.searchString = self.searchString
				}
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.frame(maxWidth:300)
				
				UnsplashOrientationView(filter:filter)
				UnsplashColorView(filter:filter)
				
				Spacer()
				
				Button("Save")
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
    
    /// This function is called whenever a filter parameter in the search bar was changed
	
//    func updateFilter()
//    {
//		let searchString = self.filterData.searchString
//
//		var orientation:UnsplashFilter.Orientation?  = self.filterData.orientation
//		if orientation == .any { orientation = nil }
//
//		var color:UnsplashFilter.Color? = self.filterData.color
//		if color == .any { color = nil }
//
//		self.selectedContainer.filter = UnsplashFilter(
//			searchString:searchString,
//			orientation:orientation,
//			color:color)
//    }
}


//----------------------------------------------------------------------------------------------------------------------


struct UnsplashOrientationView : View
{
	@ObservedObject var filter:UnsplashFilter
	
	var body: some View
	{
		MenuButton(self.filter.orientation.localizedName)
		{
			ForEach(UnsplashFilter.Orientation.allCases, id:\.self)
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


struct UnsplashColorView : View
{
	@ObservedObject var filter:UnsplashFilter
	
	var body: some View
	{
		MenuButton(self.filter.color.localizedName)
		{
			ForEach(UnsplashFilter.Color.allCases, id:\.self)
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


//class UnsplashFilterData : ObservableObject
//{
//	@Published var searchString:String = ""
//
//	@Published var orientation:UnsplashFilter.Orientation = .any
//	{
//		didSet { self.didChange() }
//	}
//	
//	@Published var color:UnsplashFilter.Color = .any
//	{
//		didSet { self.didChange() }
//	}
//	
//	var didChange:()->Void = { }
//}


//----------------------------------------------------------------------------------------------------------------------
