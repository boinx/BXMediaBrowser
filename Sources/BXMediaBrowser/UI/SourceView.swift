//
//  MediaBrowserView.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct SourceView : View
{
	@ObservedObject var source:Source
	
	public var body: some View
    {
		BXDisclosureView(isExpanded:self.$source.isExpanded,
		
			header:
			{
				BXDisclosureButton(source.name, isExpanded:self.$source.isExpanded)
					.leftAligned()
					.font(.system(size:13))
					.padding(.vertical,2)
			},
			
			body:
			{
				VStack(alignment:.leading, spacing:2)
				{
					ForEach(source.containers)
					{
//						ViewFactory.shared.build(with:$0)
						ContainerView(container:$0)
					}
				}
				.padding(.leading,20)
				.onAppear { self.loadIfNeeded() }
			})
			.id(source.identifier)
    }
    
    func loadIfNeeded()
    {
		if !source.isLoaded
		{
			source.load()
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------


public struct FolderSourceView : View
{
	@ObservedObject var source:Source
	
	public var body: some View
    {
		VStack(alignment:.leading, spacing:6)
		{
			ForEach(source.containers)
			{
				ContainerView(container:$0)
			}
		}
		.id(source.identifier)
		.onAppear { self.loadIfNeeded() }
    }
    
    func loadIfNeeded()
    {
		if !source.isLoaded
		{
			source.load()
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------
