//
//  MediaBrowserView.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


/// This view displays a single Section within a LibaryView

public struct SectionView : View
{
	/// Data Model
	
	@ObservedObject var section:Section
	
	// Build View
	
	public var body: some View
    {
		VStack(alignment:.leading, spacing:4)
		{
			// Section name is optional
			
			if let name = section.name
			{
				HStack
				{
					Text(name.uppercased()).font(.system(size:11))
						
					Spacer()
				
					if let addSourceHandler = section.addSourceHandler
					{
						Image(systemName:"plus.circle").onTapGesture
						{
							addSourceHandler(section)
						}
					}
				}
				.opacity(0.6)
			}
			
			// FolderSources are displayed differently than other sources (do not show source name)
			
			ForEach(section.sources)
			{
//				ViewFactory.shared.build(with:$0)
				if $0 is FolderSource
				{
					FolderSourceView(source:$0)
				}
				else
				{
					SourceView(source:$0)
				}
			}
		}
		
		// Layout
		
		.padding(.bottom,4)
		.padding(.bottom,12)
		
		// Apply id to optimized view hierarchy rebuilding
		
		.id(section.identifier)
    }
}


//----------------------------------------------------------------------------------------------------------------------
