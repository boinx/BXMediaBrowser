//
//  MediaBrowserView.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

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
//						ViewFactory.shared.build(with:$0)
						ContainerView(container:$0)
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


