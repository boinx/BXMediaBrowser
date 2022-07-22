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
import BXSwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct PexelsContainerView : View
{
	// Model
	
	@ObservedObject var container:PexelsContainer
    @EnvironmentObject var library:Library
	@Environment(\.colorScheme) private var colorScheme
	
    var pexelsFilter:PexelsFilter?
    {
        self.container.filter as? PexelsFilter
    }
    
	// Init
	
	public init(with container:PexelsContainer)
	{
		self.container = container
	}
	
	// View
	
	public var body: some View
    {
        // Live search container
        
        if container.saveHandler != nil, let pexelsFilter = self.pexelsFilter
        {
            HStack(spacing:10)
            {
                NativeSearchField(value:searchStringBinding, placeholderString:searchPlaceholder, continuousUpdates:false, onBegan:selectContainer)
                    .strokeBorder()
					.background(searchFieldBackground)
                    .frame(minWidth:100, maxWidth:240)
               
                PexelsOrientationButton(filter:pexelsFilter)
					.simultaneousGesture( TapGesture().onEnded
					{
						self.selectContainer()
					})

                PexelsColorButton(filter:pexelsFilter, strokeColor:textColor)
					.simultaneousGesture( TapGesture().onEnded
					{
						self.selectContainer()
					})
					.padding(.trailing,-10)
					
                Spacer()
                
				self.saveContainerButton
					.padding(.leading,-10)
            }
            .padding(.leading,9)
            .padding(.vertical,2)
            
            // Display highlight when this container is selected
            
            .background(selectionBackgroundView)
			.foregroundColor(textColor)
			
            // Clicking selects the container
            
             .contentShape(Rectangle().size(width:1000,height:20).offset(x:-100,y:0))  // Make hit target wider so that whole row is clickable!
            
            .simultaneousGesture( TapGesture().onEnded
                                  {
                self.selectContainer()
            })
        }
        
        // Saved searches
        
        else
        {
            ContainerView(with:container)
        }
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension PexelsContainerView
{
	/// Selects this container
	
	func selectContainer()
	{
		self.library.selectedContainer = self.container

        if !container.isLoaded && !container.isLoading
        {
            container.load()
        }
	}
	
    // The selected container row is hilighted. Please note that the highlight is made wider and offset,
    // to compensate for the insets of expanded disclosure views. We want the color highlight to go
    // from edge to edge.
            
    var selectionBackgroundView: some View
    {
        GeometryReader
        {
            selectionBackgroundColor
                .frame(width:$0.size.width+1000, height:$0.size.height)
                .offset(x:-900, y:0)
        }
    }
    
    var selectionBackgroundColor:Color
    {
        library.selectedContainer === self.container ? .accentColor : .clear
    }
    
    var textColor:Color
    {
		library.selectedContainer === self.container ? .white : .primary
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension PexelsContainerView
{
    /// Returns the localized search field placeholder string
    
    var searchPlaceholder:String
    {
        NSLocalizedString("Search", bundle:.BXMediaBrowser, comment:"Placeholder")
    }

    var searchStringBinding:Binding<String>
    {
        Binding<String>(
			get:{ self.container.filter.searchString },
			set:{ self.container.filter.searchString = $0 }
        )
    }
    
    var searchFieldBackground: some View
    {
		RoundedRectangle(cornerRadius:5)
			.fill(searchBackgroundColor)
			.padding(1.5)
    }
    
    var searchBackgroundColor:Color
    {
		colorScheme == .dark ? .black.opacity(0.4) : .white.opacity(0.4)
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension PexelsContainerView
{
	var saveContainerButton: some View
	{
		BXImage(systemName:"plus.circle").onTapGesture
		{
			self.container.save()
		}
		.reducedOpacityWhenDisabled()
		.disabled(self.container.filter.searchString.isEmpty)
	}
}


//----------------------------------------------------------------------------------------------------------------------

