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
	@State private var searchString:String = ""
	
	// Init
	
	public init(with selectedContainer:Container, filter:UnsplashFilter)
	{
		self.selectedContainer = selectedContainer
		self.filter = filter
		self.searchString = filter.searchString
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
		HStack(spacing:10)
		{
			Text(description)
			Spacer()
			RatingFilterView(rating:self.$filter.rating).fixedSize()
		}
		.padding(.horizontal,20)
		.padding(.vertical,10)
		.frame(height:42)
    }

    var saveTitle:String
    {
		NSLocalizedString("Save", bundle:.BXMediaBrowser, comment:"Button Title")
    }
    
    var searchPlaceholder:String
    {
        NSLocalizedString("Search", bundle:.BXMediaBrowser, comment:"Placeholder")
    }
}


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashOrientationButton : View
{
    // Model
    
    @ObservedObject var filter:UnsplashFilter
    
    public var body: some View
    {
        BXImage(systemName:filter.orientation.icon)
            .font(.system(size:17, weight:.regular))
            .popupMenu(self.orientationMenuItems(value:self.$filter.orientation))
    }
    
    func orientationMenuItems(value:Binding<UnsplashFilter.Orientation>) -> [BXMenuItemSpec]
    {
        UnsplashFilter.Orientation.allCases.map
        {
            orientation in
            
            BXMenuItemSpec.action(icon:nil, title:orientation.localizedName, state: { value.wrappedValue == orientation ? .on : .off })
            {
                value.wrappedValue = orientation
            }
        }
    }
}


//----------------------------------------------------------------------------------------------------------------------


public struct UnsplashColorButton : View
{
    // Model
    
    @ObservedObject var filter:UnsplashFilter
    var strokeColor:Color = .primary
   
    public var body: some View
    {
        ColorIconView(color:filter.color.color, strokeColor:strokeColor, allowBW:true)
            .popupMenu(self.colorMenuItems(value:self.$filter.color))
    }
    
    func colorMenuItems(value:Binding<UnsplashFilter.Color>) -> [BXMenuItemSpec]
    {
        UnsplashFilter.Color.allCases.map
        {
            color in
            
            BXMenuItemSpec.action(icon:nil, title:color.localizedName, state: { value.wrappedValue == color ? .on : .off })
            {
                value.wrappedValue = color
            }
        }
    }
}


//----------------------------------------------------------------------------------------------------------------------


struct ColorIconView : View
{
	var color:SwiftUI.Color
    var strokeColor:Color = .primary
	var size:CGFloat = 16
	var allowBW = false
	
	var body: some View
	{
		self.patch
			.cornerRadius(0.5 * size)
			.frame(width:size, height:size)
			.overlay(
				Circle().strokeBorder(strokeColor, lineWidth:1, antialiased:true)
			)
	}
	
	@ViewBuilder var patch: some View
	{
		if color == .clear
		{
			AngularGradient(
				gradient: Gradient(colors:[.red,.yellow,.green,.blue,.red]),
				center: .center)
		}
		else if color == .gray && allowBW
		{
			LinearGradient(
				colors: [.black,.white],
				startPoint: UnitPoint(x:0.35,y:0.5),
				endPoint: UnitPoint(x:0.65,y:0.5))
		}
		else
		{
			color
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
