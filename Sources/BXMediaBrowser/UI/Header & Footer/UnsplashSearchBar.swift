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


import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashSearchBar : View
{
	// Model
	
	@ObservedObject var selectedContainer:Container
	
	// For some reason having more than one @State var crashes SwiftUI here, so we'll bundle the three needed
	// properties in a helper class called UsplashFilterData. Seems to be a functioning workaround.
	
	@State private var filterData = UnsplashFilterData()
	
//	@State private var searchString:String = ""
//	@State private var orientation:String = "" // UnsplashFilter.Orientation.any.rawValue
//	@State private var color:String = "" // UnsplashFilter.Color.any.rawValue
	
	// Init
	
	public init(with selectedContainer:Container)
	{
		self.selectedContainer = selectedContainer
		
		if let filter = selectedContainer.filter as? UnsplashFilter
		{
			self.filterData.searchString = filter.searchString
			self.filterData.orientation = filter.orientation?.rawValue ?? ""
			self.filterData.color = filter.color?.rawValue ?? ""
		}
		
		self.filterData.didChange = self.updateFilter
	}
	
	// View
	
	public var body: some View
    {
		HStack
		{
			TextField("Search", text:self.$filterData.searchString)
			{
				self.updateFilter()
			}
			.textFieldStyle(RoundedBorderTextFieldStyle())
			.frame(maxWidth:300)
			
			Spacer()
			
			Picker("Orientation:", selection: self.$filterData.orientation)
			{
				ForEach(UnsplashFilter.Orientation.allValues, id:\.self)
				{
					Text($0)
				}
            }
			.pickerStyle(.menu)

			Picker("Color:", selection: self.$filterData.color)
			{
				ForEach(UnsplashFilter.Color.allIdentifiers, id:\.self)
				{
					Text($0)
				}
           }
			.pickerStyle(.menu)
		}
		.padding(10)
    }
    
    func updateFilter()
    {
		let searchString = self.filterData.searchString
		
		var orientation = UnsplashFilter.Orientation(rawValue: self.filterData.orientation)
		if self.filterData.orientation == "" { orientation = nil }

		var color = UnsplashFilter.Color(rawValue: self.filterData.color)
		if self.filterData.color == "" { color = nil }
		
		self.selectedContainer.filter = UnsplashFilter(
			searchString:searchString,
			orientation:orientation,
			color:color)
    }
}


//----------------------------------------------------------------------------------------------------------------------


struct UnsplashColorButton : View
{
	var color:UnsplashFilter.Color
	var action:(UnsplashFilter.Color)->Void
	
	var body: some View
	{
		color.color
			.frame(width:16, height:16)
			.cornerRadius(8)
			.overlay( Circle().strokeBorder(Color.primary, lineWidth:0.5, antialiased:true) )
			.onTapGesture { action(color) }
	}
}


//----------------------------------------------------------------------------------------------------------------------


class UnsplashFilterData : ObservableObject
{
	@Published var searchString:String = ""

	@Published var orientation:String = ""
	{
		didSet { self.didChange() }
	}
	
	@Published var color:String = ""
	{
		didSet { self.didChange() }
	}
	
	var didChange:()->Void = { }
}


//----------------------------------------------------------------------------------------------------------------------
