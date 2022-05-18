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
				HStack
				{
					CustomDisclosureButton(icon:source.icon, label:source.name, isExpanded:self.$source.isExpanded)
						.leftAligned()
						.padding(.vertical,2)
						
					Spacer()
					
					self.statusView
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
					VStack(spacing:12)
					{
						Text(errorMessage)
							.lineLimit(nil)
							#if os(macOS)
							.controlSize(.small)
							#endif

						errorRecovery()
					}
					.padding(12)
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
		if lightroom.status != .ok
		{
			BXImage(systemName:errorIcon)
				.foregroundColor(errorColor)
				.onTapGesture { self.isShowingPopover = true }
				.popover(isPresented: self.$isShowingPopover)
				{
					self.statusPopoverView
						.padding()
						.frame(width:260)
				}
		}
		else
		{
			EmptyView()
		}
    }
    
    
    var statusPopoverView: some View
    {
		VStack(spacing:12)
		{
			HStack
			{
				BXImage(systemName:errorIcon)
					.foregroundColor(errorColor)
					
				Text(errorTitle)
					.bold()
					.lineLimit(1)
			}

			Text(errorMessage)
				.lineLimit(nil)
				#if os(macOS)
				.controlSize(.small)
				#endif

			errorRecovery()
		}
    }
    
    var errorIcon:String
    {
		switch lightroom.status
		{
			case .noAccess: return "exclamationmark.octagon.fill"
			case .notRunning: return "exclamationmark.triangle.fill"
			default: return ""
		}
    }
    
    var errorColor:Color
    {
		switch lightroom.status
		{
			case .noAccess: return .red
			case .notRunning: return .yellow
			default: return .primary
		}
    }
    
	var errorTitle:String
    {
		switch lightroom.status
		{
			case .noAccess: return "Missing Access Rights"
			case .notRunning: return "Lightroom Classic Not Running"
			default: return ""
		}
    }
    
    var errorMessage:String
    {
		switch lightroom.status
		{
			case .noAccess: return "The Lightroom library is not readable. Please grant read access rights for its parent folder."
			case .notRunning: return "To access the library Lightroom Classic must be running in the background."
			default: return ""
		}
    }
    
    @ViewBuilder func errorRecovery() -> some View
    {
		if lightroom.status == .noAccess
		{
			Button("Grant Access")
			{
				self.isShowingPopover = false
				source.grantAccess()
			}
		}
		else if lightroom.status == .notRunning
		{
			Button("Launch Lightroom")
			{
				self.isShowingPopover = false
				
				lightroom.launch()
				{
					_ in source.load()
				}
			}
		}
    }
}


//----------------------------------------------------------------------------------------------------------------------
