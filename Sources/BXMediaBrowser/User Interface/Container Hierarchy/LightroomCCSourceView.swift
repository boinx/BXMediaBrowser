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


public struct LightroomCCSourceView : View
{
	// Model
	
	@ObservedObject var source:LightroomCCSource
	@ObservedObject var lightroom:LightroomCC
	
	// Environment
	
	@EnvironmentObject var library:Library
	@Environment(\.viewFactory) private var viewFactory

	// Init
	
	public init(with source:LightroomCCSource, _ lightroom:LightroomCC)
	{
		self.source = source
		self.lightroom = lightroom
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
						.leftAligned()
						.font(.system(size:13))
						.padding(.vertical,2)
						
					Spacer()
					
					self.statusView
				}
			},
			
			body:
			{
				if lightroom.status == .loggedIn
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
					Button(NSLocalizedString("Login", bundle:.BXMediaBrowser, comment:"Button Title"))
					{
						self.source.grantAccess()
					}
					.centerAligned()
					.padding()
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
    
    @ViewBuilder var statusView: some View
    {
		if lightroom.status == .invalidClientID
		{
			BXImage(systemName:"exclamationmark.octagon.fill")
				.foregroundColor(.red)
		}
		else if lightroom.status == .currentlyUnavailable
		{
			BXImage(systemName:"exclamationmark.triangle.fill")
				.foregroundColor(.yellow)
		}
		else if lightroom.status == .loggedOut
		{
			self.accountButton()
				.id("loggedOut")
		}
		else
		{
			self.accountButton()
				.id(lightroom.userID)
		}
    }
    
    
    func accountButton() -> some View
    {
		var items:[BXMenuItemSpec] = []
		
		if lightroom.status == .loggedOut
		{
			items += BXMenuItemSpec.action(title:NSLocalizedString("Login", bundle:.BXMediaBrowser, comment:"Button Title"))
			{
				self.source.grantAccess()
			}
		}
		else
		{
			if let user = lightroom.userEmail ?? lightroom.userName
			{
				items += BXMenuItemSpec.regular(title:user, value:0, isEnabled:false)
			}
			
			items += BXMenuItemSpec.action(title:NSLocalizedString("Logout", bundle:.BXMediaBrowser, comment:"Button Title"))
			{
				self.source.revokeAccess()
			}
		}
		
		return BXImage(systemName:"person.crop.circle").popupMenu(items)
    }
}


//----------------------------------------------------------------------------------------------------------------------
