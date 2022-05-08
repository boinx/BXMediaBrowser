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


#if os(macOS)

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


/// ObjectBrowserView displays a header, ObjectCollectionView, and a footer.
///
/// Depending on the currenty selected Container, different subviews will be displayed.

public struct ObjectBrowserView : View
{
	// Model
	
	var container:Container?
	@ObservedObject var uiState:UIState
	
	// Environment
	
	@Environment(\.viewFactory) private var viewFactory
	
	// Init
	
	public init(for container:Container?, uiState:UIState)
	{
		self.container = container
		self.uiState = uiState
	}
	
	// View
	
	public var body: some View
    {
		let cellType = viewFactory.objectCellType(for:container, uiState:uiState)
		
		return VStack(spacing:0)
		{
			viewFactory.objectsHeaderView(for:container, uiState:uiState)
				.id(headerID)
				
			Color.primary.opacity(0.2).frame(height:1) // Divider line
			
			ObjectCollectionView(container:container, cellType:cellType, uiState:uiState)
				
			Color.primary.opacity(0.2).frame(height:1) // Divider line

			viewFactory.objectsFooterView(for:container, uiState:uiState)
				.id(footerID)
		}
		.frame(minWidth:ObjectCollectionView.minWidth, maxWidth:.infinity) // WORKAROUND 3 (see ObjectCollectionView-macOS.swift)
   }
   
   var headerID:String
   {
		"ObjectBrowserView.header." + (container?.identifier ?? "")
   }
   
   var footerID:String
   {
		"ObjectBrowserView.footer." + (container?.identifier ?? "")
   }
}


//----------------------------------------------------------------------------------------------------------------------


#endif
