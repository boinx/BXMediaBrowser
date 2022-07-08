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


#if canImport(iMedia) && os(macOS)

import BXSwiftUI
import BXSwiftUtils
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct LightroomClassicSourceView : View
{
	// Model
	
	@ObservedObject var source:LightroomClassicSource
	@ObservedObject var lightroom:LightroomClassic
	@State private var isShowingPopover = false
	
	// Environment
	
	@EnvironmentObject var library:Library
	@Environment(\.viewFactory) private var viewFactory

	// Init
	
	public init(with source:LightroomClassicSource, _ lightroom:LightroomClassic)
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
				CustomDisclosureButton(icon:source.icon, label:source.name, isExpanded:self.$source.isExpanded)
					.leftAligned()
					.padding(.vertical,2)
					
					.contextMenu
					{
						Button(NSLocalizedString("RevokeAccess.button", tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Button Title"))
						{
							source.revokeAccess()
						}
					}
			},
			
			body:
			{
				if lightroom.status == .ok
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
					self.statusView.padding(12)
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


extension LightroomClassicSourceView
{
    /// This view displays login status or any error conditions
	
    @ViewBuilder var statusView: some View
    {
		HStack(alignment:.top, spacing:12)
		{
			BXImage(systemName:"exclamationmark.triangle.fill")
				.foregroundColor(.yellow)
					
			VStack(alignment:.leading, spacing:12)
			{
				Text(errorTitle)
					.bold()
					.lineLimit(nil)
					
				Text(errorMessage)
					.lineLimit(nil)
					#if os(macOS)
					.controlSize(.small)
					#endif

				errorRecoveryButton()
					#if os(macOS)
					.controlSize(.small)
					#endif
			}
		}
    }
    
	/// Creates a recovery button for the current error status
	
    @ViewBuilder func errorRecoveryButton() -> some View
    {
		if lightroom.status == .noAccess
		{
			Button(NSLocalizedString("GrantAccess.button", tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Button Title"))
			{
				self.isShowingPopover = false
				source.grantAccess()
			}
		}
		else if lightroom.status == .notRunning
		{
			Button(NSLocalizedString("LaunchLightroom.button", tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Button Title"))
			{
				self.isShowingPopover = false
				
				lightroom.launch()
				{
					_ in
					source.isExpanded = true
					source.load()
				}
			}
		}
    }
    
	/// Returns the title for the current error status
	
	var errorTitle:String
    {
		switch lightroom.status
		{
			case .noAccess: return NSLocalizedString("Status.noAccess.title", tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Alert Title")
			case .notRunning: return NSLocalizedString("Status.notRunning.title", tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Alert Title")
			default: return ""
		}
    }
    
    /// Returns the description for the current error status
	
    var errorMessage:String
    {
		switch lightroom.status
		{
			case .noAccess: return NSLocalizedString("Status.noAccess.message", tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Alert Message")
			case .notRunning: return NSLocalizedString("Status.notRunning.message", tableName:"LightroomClassic", bundle:.BXMediaBrowser, comment:"Alert Message")
			default: return ""
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------


#endif
