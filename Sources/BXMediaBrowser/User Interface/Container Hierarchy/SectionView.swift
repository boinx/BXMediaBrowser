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


/// This view displays a single Section within a LibaryView

public struct SectionView : View
{
	// Model
	
	@ObservedObject var section:Section
	
	// Environment
	
	@EnvironmentObject var library:Library
	@Environment(\.viewFactory) private var viewFactory

	// State
	
//	@State var isExpanded = true
	@State var isHovering = false
	
	// Init
	
	public init(with section:Section)
	{
		self.section = section
	}
	
	// View
	
	public var body: some View
    {
		BXDisclosureView(isExpanded:self.$section.isExpanded, spacing:4,
		
			header:
			{
				// Section name is optional
				
				if let name = section.name
				{
					HStack
					{
						self.sectionName(name)

						Spacer()
					
						// The optional + button will be displayed if a handler was provided
						
						if let addSourceHandler = section.addSourceHandler, self.section.isExpanded
						{
							BXImage(systemName:"plus.circle").onTapGesture
							{
								addSourceHandler(section)
							}
						}
					}
				}
			},
			
			body:
			{
				// Display list of Sources
					
				EfficientVStack(alignment:.leading, spacing:4)
				{
					ForEach(section.sources)
					{
						viewFactory.sourceView(for:$0)
					}
				}
			})
		
		// Layout
		
		.padding(.horizontal)
		.padding(.bottom,12)

		// Whenever the current state changes, save it to persistent storage
		
		.onReceive(section.$sources)
		{
			_ in library.saveState()
		}
		.onReceive(section.$isExpanded)
		{
			_ in library.saveState()
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension SectionView
{
    public static func shouldDisplay(_ section:Section) -> Bool
    {
		!section.sources.isEmpty || section.addSourceHandler != nil
    }
    
    func sectionName(_ name:String) ->  some View
    {
		HStack(spacing:4)
		{
			Text(name.uppercased())
				.font(.caption)
				.opacity(0.6)
			
			if isHovering
			{
				self.disclosureButton
			}
		}
		
		// Make hit target larger
		
		.padding(8)
		.contentShape(Rectangle())
		
		#if os(macOS)
		.onHover
		{
			self.isHovering = $0
		}
		#endif
		
		// Add click gesture to expand/collapse
		
		.onTapGesture
		{
			withAnimation { self.section.isExpanded.toggle() }
		}
		
		// Compensate for earlier enlargment
		
		.padding(-8)
    }
    
    var disclosureButton: some View
    {
		BXImage(systemName:"chevron.forward")
			.opacity(0.65)
			.padding(-1)
			.scaleEffect(0.7)
			.rotationEffect(.degrees(self.section.isExpanded ? 90 : 0))
			.offset(x:0, y:-1)
    }
}


//----------------------------------------------------------------------------------------------------------------------
