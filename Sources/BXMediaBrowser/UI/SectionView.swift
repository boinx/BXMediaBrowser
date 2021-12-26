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
