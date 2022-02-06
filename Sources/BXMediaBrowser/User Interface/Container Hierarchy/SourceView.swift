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


public struct SourceView : View
{
	// Model
	
	@ObservedObject var source:Source
	
	// Environment
	
	@EnvironmentObject var library:Library
	@Environment(\.viewFactory) private var viewFactory

	// Init
	
	public init(with source:Source)
	{
		self.source = source
	}
	
	// View
	
	public var body: some View
    {
		BXDisclosureView(isExpanded:self.$source.isExpanded, spacing:0,
		
			header:
			{
				CustomDisclosureButton(icon:source.icon, label:source.name, isExpanded:self.$source.isExpanded)
					.leftAligned()
					.font(.system(size:13))
					.padding(.vertical,2)
			},
			
			body:
			{
				BestVStack(alignment:.leading, spacing:2)
				{
					ForEach(source.containers)
					{
						viewFactory.containerView(for:$0)
					}
				}
				.padding(.leading,20)
				.onAppear { self.loadIfNeeded() }
			})
//			.id(source.identifier)
			
			// Whenever the current state changes, save it to persistent storage
		
			.onReceive(source.$containers)
			{
				_ in library.saveState()
			}
			.onReceive(source.$isExpanded)
			{
				_ in library.saveState()
			}
    }
    
    func loadIfNeeded()
    {
		if !source.isLoaded && !source.isLoading
		{
			source.load()
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------
