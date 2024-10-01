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
import BXSwiftUtils
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct PhotosSourceView : View
{
	// Model
	
	@ObservedObject var source:PhotosSource
	
	// Environment
	
	@EnvironmentObject var library:Library
	@Environment(\.viewFactory) private var viewFactory

	// Init
	
	public init(with source:PhotosSource)
	{
		self.source = source
	}
	
	// View
	
	public var body: some View
    {
		BXDisclosureView(isExpanded:self.$source.isExpanded, spacing:0,
		
			header:
			{
                HStack
                {
                    CustomDisclosureButton(icon:source.icon, label:source.name, isExpanded:self.$source.isExpanded)
                    Spacer()

                    if !source.hasAccess
                    {
                        BXImage(systemName:"exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .onTapGesture
                            {
                                source.isExpanded = true
                            }
                    }
                }
                .padding(.vertical,2)
			},
			
			body:
			{
                if source.hasAccess
				{
                    EfficientVStack(alignment:.leading, spacing:2)
                    {
                        ForEach(source.containers)
                        {
                            viewFactory.containerView(for:$0)
                        }
                    }
                    .padding(.leading,20)
				}
				else
				{
					self.statusView
                        .padding(.vertical,12)
                        .padding(.horizontal,34)
				}
			})
			
			// Whenever the current state changes, save it to persistent storage
		
			.onReceive(source.$isExpanded)
			{
				_ in library.saveState()
			}
			.onReceive(source.$containers)
			{
				_ in library.saveState()
			}
    }
}


//----------------------------------------------------------------------------------------------------------------------


extension PhotosSourceView
{
    /// Displays an error message about missing access rights
	
    @ViewBuilder var statusView: some View
    {
        #if os(macOS)
        
//		HStack(alignment:.top, spacing:12)
//		{
//			BXImage(systemName:"exclamationmark.triangle.fill")
//				.foregroundColor(.yellow)
					
			VStack(alignment:.leading, spacing:12)
			{
                Text(NSLocalizedString("Status.noAccess.title", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Alert Title"))
                    .bold()
                
                Text(NSLocalizedString("Status.noAccess.message", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Alert Message"))
                    .controlSize(.small)
                
                Button(NSLocalizedString("Status.noAccess.button", tableName:"Photos", bundle:.BXMediaBrowser, comment:"Alert Button"))
                {
                    self.openSystemSettings()
                }
			}
//		}
        
        #else
        EmptyView()
        #endif
    }
    
    /// Opens System Settings > Privacy & Security > Photos
    
    func openSystemSettings()
    {
        #if os(macOS)
        guard let url = URL(string:"x-apple.systempreferences:com.apple.preference.security?Privacy_Photos") else { return }
        NSWorkspace.shared.open(url)
        #endif
    }
 }


//----------------------------------------------------------------------------------------------------------------------
