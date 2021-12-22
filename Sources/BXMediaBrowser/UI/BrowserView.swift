//
//  BrowserView.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct BrowserView : View
{
	@ObservedObject var library:Library

	public init(with library:Library)
	{
		self.library = library
	}
	
	public var body: some View
    {
		HSplitView
		{
			ScrollView
			{
				LibraryView(library:library)

//				ViewFactory.shared.build(with:library)
					.padding()
					.frame(minWidth:240)
			}
			.background(.thinMaterial)
			
			if let container = library.selectedContainer
			{
				ObjectsView(container:container)
					.environmentObject(library)
					.layoutPriority(1)
			}
			else
			{
				EmptyObjectsView()
					.layoutPriority(1)
			}
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------


