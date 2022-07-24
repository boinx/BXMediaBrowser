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


public struct MusicSourceView : View
{
	// Model
	
	@ObservedObject var source:MusicSource
	@ObservedObject var app:MusicApp
	
	// Environment
	
	@EnvironmentObject var library:Library
	@Environment(\.viewFactory) private var viewFactory
	@Environment(\.parentWindow) private var parentWindow

	// State
	
	@State private var isShowingPopover = false

	// Init
	
	public init(with source:MusicSource, _ app:MusicApp)
	{
		self.source = source
		self.app = app
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
						.padding(.vertical,2)
						
					Spacer()
					
					self.accessAlertIcon
				}
			},
			
			body:
			{
				EfficientVStack(alignment:.leading, spacing:2)
				{
					ForEach(source.containers)
					{
						viewFactory.containerView(for:$0)
					}
				}
				.padding(.leading,20)
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
    
    /// This view displays login status or any error conditions
	
    @ViewBuilder var accessAlertIcon: some View
    {
		if !app.isReadable
		{
			BXImage(systemName:"exclamationmark.triangle.fill")
				.foregroundColor(.yellow)
				.onTapGesture { self.isShowingPopover = true }
				.popover(isPresented: self.$isShowingPopover)
				{
					MusicAccessAlertView(source:source, isPresented:self.$isShowingPopover)
				}
		}
    }
 }


//----------------------------------------------------------------------------------------------------------------------


public struct MusicAccessAlertView : View
{
	// Params
	
	var source:MusicSource
	@Binding var isPresented:Bool

	// Environment
	
	@EnvironmentObject var library:Library
	
	// Build View
	
	public var body: some View
    {
		let name = MusicApp.shared.rootFolderURL?.lastPathComponent ?? ""
		
		return VStack(alignment:.leading, spacing:12)
		{
			Text("⚠️ Missing Access Rights")
				.bold()
				.lineLimit(1)
				.centerAligned()

			Text("Please grant read access to the folder \"\(name)\" to make the audio files usable.")
				.lineLimit(nil)
				#if os(macOS)
				.controlSize(.small)
				#endif
			
			Button("Grant Access")
			{
				self.isPresented = false
				
				source.grantAccess()
				{
					if $0
					{
						source.load()
						library.saveState()
					}
				}
			}
			.centerAligned()
		}
		.padding()
		.buttonStyle(BXStrokedButtonStyle())
		.frame(width:260)
    }
}


//----------------------------------------------------------------------------------------------------------------------
