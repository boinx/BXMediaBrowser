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


public struct MusicFilterBar : View
{
	// Model
	
	@ObservedObject var selectedContainer:Container
	@ObservedObject var filter:MusicFilter
	@EnvironmentObject var sortController:SortController
	
	// Init
	
	public init(with selectedContainer:Container, filter:MusicFilter)
	{
		self.selectedContainer = selectedContainer
		self.filter = filter
	}
	
	// View
	
	public var body: some View
    {
		HStack
		{
			// Search field
			
			TextField("Search", text:self.$filter.searchString)
				.frame(maxWidth:300)
				.textFieldStyle(RoundedBorderTextFieldStyle())

			Spacer()

			// Sort order
			
			if !selectedContainer.allowedSortKinds.isEmpty
			{
				Text("Sort by:")
				
				MenuButton(sortController.kind.localizedName)
				{
					ForEach(sortController.allowedSortKinds, id:\.self)
					{
						kind in
						
						Button(kind.localizedName)
						{
							sortController.kind = kind
						}
					}
				}
				.fixedSize()
				
				if #available(macOS 11, iOS 13, *)
				{
					SwiftUI.Image(systemName:directionIcon)
						.padding(.vertical,6)
						.padding(.horizontal,2)
						.contentShape(Rectangle())
						.onTapGesture
						{
							sortController.toggleDirection()
						}
				}
			}
		}
		.padding(.horizontal,20)
		.padding(.vertical,10)
    }
    
    var directionIcon:String
    {
		sortController.direction == .ascending ? "chevron.up" : "chevron.down"
    }
}


//----------------------------------------------------------------------------------------------------------------------

