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


/// This is the root view for a BXMediaBrowser.Library

public struct LibraryView : View
{
	// Model
	
	@ObservedObject var library:Library
	
	// Environment
	
	@Environment(\.viewFactory) private var viewFactory
	
	// Init
	
	public init(with library:Library)
	{
		self.library = library
	}
	
	// View
	
	public var body: some View
    {
		EfficientVStack(alignment:.leading, spacing:4)
		{
			ForEach(library.sections)
			{
				if SectionView.shouldDisplay($0)
				{
					viewFactory.sectionView(for:$0)
				}
			}
		}
		
		// Pass Library reference down the view hierarchy. This is needed for setting the selected Container.
		
		.environmentObject(library)

		// Set id for finding in a hierarchy
		
		#if os(macOS)
		.identifiableBackgroundView(withID:"BXMediaBrowser.LibraryView")
		#endif
		
		// When important properties of the library have changed, then save the current state
		
//		.onReceive(library.$selectedContainer)
//		{
//			_ in library.setNeedsSaveState()
//		}
   }
}


//----------------------------------------------------------------------------------------------------------------------



