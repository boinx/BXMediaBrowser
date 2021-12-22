//
//  MediaBrowserView.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


/// This is the root view for a BXMediaBrowser.Library

public struct LibraryView : View
{
	// Data Model
	
	@ObservedObject var library:Library
	
	// Build View
	
	public var body: some View
    {
		VStack(alignment:.leading, spacing:4)
		{
			ForEach(library.sections)
			{
//				ViewFactory.shared.build(with:$0)
				SectionView(section:$0)
			}
		}
		
		// Pass Library reference down the view hierarchy. This is needed for setting the selected Container.
		
 		.environmentObject(library)
//		.frame(minWidth:400)
    }
}


//----------------------------------------------------------------------------------------------------------------------


