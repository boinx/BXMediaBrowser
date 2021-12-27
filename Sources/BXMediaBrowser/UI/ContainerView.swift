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


public struct ContainerView : View
{
	// Data Model
	
	@ObservedObject var container:Container
	@EnvironmentObject var library:Library
	
	// Build View
	
	public var body: some View
    {
		let icon = container.icon ?? "folder"
		
		return BXDisclosureView(isExpanded:self.$container.isExpanded,
		
			header:
			{
				// Container name
				
				HStack(spacing:4)
				{
					BXDisclosureButton("", isExpanded:self.$container.isExpanded)
					Image(systemName:icon)
					
					Text(container.name)
						.lineLimit(1)
						.truncationMode(.tail)
						.padding(.trailing,-15)
						
					Spacer()
					
					if container.isLoading
					{
						BXSpinningWheel(size:.small)
							.colorScheme(.dark)
					}
					else if let removeHandler = container.removeHandler
					{
						Image(systemName:"minus.circle").onTapGesture
						{
							removeHandler(container)
						}
					}
				}
				.font(.system(size:13))
				
				// Styling
				
				.padding(.vertical,2)
				.background(backgroundView)
				.foregroundColor(textColor)
				
				// Clicking selects the container
				
				.contentShape(Rectangle().size(width:1000,height:20).offset(x:-100,y:0))  // Make hit target wider so that whole row is clickable!
				
				.simultaneousGesture( TapGesture().onEnded
				{
					self.library.selectedContainer = self.container
					self.loadIfNeeded()
				})
			},
			
			body:
			{
				// Subcontainers
				
				VStack(alignment:.leading, spacing:0)
				{
					ForEach(container.containers)
					{
						ViewFactory.shared.hierarchyView(for:$0)
					}
				}
				.padding(.leading,20)
			})
			.id(container.identifier)
    }
    
    // Subcontainers are loaded lazily when expanding this Container
    
    func loadIfNeeded()
    {
		if !container.isLoaded
		{
			container.load()
			{
				library.didLoadSelectedContainer += 1
			}
		}
    }
    
	// The selected container row is hilighted. Please note that the highlight is made wider and offset,
	// to compensate for the insets of expanded disclosure views. We want the color highlight to go
	// from edge to edge.
			
    var backgroundView: some View
    {
		GeometryReader
		{
			backgroundColor
				.frame(width:$0.size.width+1000, height:$0.size.height)
				.offset(x:-900, y:0)
		}
    }
    
    var backgroundColor:Color
    {
		library.selectedContainer === self.container ? .accentColor : .clear
    }
    
    var textColor:Color
    {
		library.selectedContainer === self.container ? .white : .primary
    }
}


//----------------------------------------------------------------------------------------------------------------------


