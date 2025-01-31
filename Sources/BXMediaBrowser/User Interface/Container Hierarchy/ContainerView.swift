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


public struct ContainerView : View
{
	// Model
	
	@ObservedObject var container:Container

	// Environment
	
	@EnvironmentObject var library:Library
	@Environment(\.viewFactory) private var viewFactory
	
	@State private var isHovering = false
	@State private var isShowingAlert = false
	
	// Init
	
	public init(with container:Container)
	{
		self.container = container
	}
	
	// View
	
	public var body: some View
    {
		return BXDisclosureView(isExpanded:self.$container.isExpanded, spacing:0,

			header:
			{
				HStack(spacing:4)
				{
					// Container name
				
					containerName()
					Spacer()
					
					// Optional loading spinner
					
					if container.isLoading
					{
						#if os(macOS)
						BXSpinningWheel(size:.small).colorScheme(.dark)
						#else
						BXSpinningWheel().colorScheme(.dark)
						#endif
					}
					
					// Optional remove button
					
					else if let removeHandler = container.removeHandler, isHovering
					{
						self.removeButton(for:removeHandler)
					}
				}
                #if os(macOS)
				.onHover
				{
					self.isHovering = $0
				}
                #endif
				
				// Styling
				
				.padding(.vertical,2)
				.background(backgroundView)
				.foregroundColor(textColor)
				
				// Clicking selects the container
				
				.simultaneousGesture( TapGesture().onEnded
				{
					self.library.selectedContainer = self.container
					self.loadIfNeeded()
				})

				// A right click selects the Container if necessary, then shows a context menu
				
				.onContextClick 	// This makes sure that the Container get's selected BEFORE the context menu is shown
				{
					self.library.selectedContainer = self.container
					self.loadIfNeeded()
				}
				.contextMenu
				{
					viewFactory.containerContextMenu(for:container)
				}
			},
			
			body:
			{
				// Subcontainers
				
				EfficientVStack(alignment:.leading, spacing:0)
				{
					ForEach(container.containers)
					{
						viewFactory.containerView(for:$0)
					}
				}
				.padding(.leading,16)
			})
			
			// Whenever the current state changes, save it to persistent storage
		
			.onReceive(container.$containers)
			{
				_ in library.setNeedsSaveState()
			}
			.onReceive(container.$isExpanded)
			{
				_ in library.setNeedsSaveState()
			}
    }
    
}


//----------------------------------------------------------------------------------------------------------------------


extension ContainerView
{
    
    @ViewBuilder func containerName() -> some View
    {
		let icon = container.icon ?? "folder"

		// Disclosure button is only visible if this Container has any sub-containers
		
		if container.canExpand
		{
			CustomDisclosureButton(icon:nil, label:"", isExpanded:self.$container.isExpanded)
				.frame(width:10)
		}
		else
		{
			Spacer().frame(width:10)
		}
		
		// Container icon
		
		if let folder = self.container as? FolderContainer, folder.isMissing
		{
			Text("⚠️")
				.onTapGesture { self.isShowingAlert = true }
				.popover(isPresented: $isShowingAlert)
				{
					MissingFolderAlertView(isPresented:$isShowingAlert)
				}
		}
		else
		{
			BXImage(systemName:icon)
				.frame(minWidth:16, alignment:.center)
				.opacity(0.5)
		}
		
			
		// Container name
		
		Text(container.name)
			.lineLimit(1)
//			.font(.body)
			.truncationMode(.tail)
			.opacity(nameAlpha)
			.padding(.trailing,-15)
    }
    
    
	var nameAlpha:Double
	{
		if let folder = self.container as? FolderContainer, folder.isMissing
		{
			return 0.5
		}
		
		return 1.0
	}
	
	/// Builds a button to remove this Container
	
	@ViewBuilder func removeButton(for removeHandler:@escaping (Container)->Void) -> some View
	{
		BXImage(systemName:"minus.circle").onTapGesture
		{
			removeHandler(container)
		}
	}


    /// Triggers loading of this container. Can be called when expanding the Container
    
    func loadIfNeeded()
    {
		if !container.isLoaded && !container.isLoading
		{
			container.load(in:library)
		}
    }


	// The selected container row is hilighted. Please note that the highlight is made wider and offset,
	// to compensate for the insets of expanded disclosure views. We want the color highlight to go
	// from edge to edge.
			
    var backgroundView: some View
    {
		GeometryReader
		{
			backgroundColor
				.frame(width:$0.size.width+1000, height:$0.size.height)
				.offset(x:-900, y:0)
		}
    }
    
    var backgroundColor:Color
    {
		library.selectedContainer === self.container ? .accentColor : .accentColor.opacity(0.005)
    }
    
    var textColor:Color
    {
		library.selectedContainer === self.container ? .white : .primary
    }
}


//----------------------------------------------------------------------------------------------------------------------


public struct MissingFolderAlertView : View
{
	// Params
	
	@Binding var isPresented:Bool

	// Build View
	
	public var body: some View
    {
		let title = NSLocalizedString("Alert.missingFolder.title", bundle:.BXMediaBrowser, comment:"Alert Title")
		let message = NSLocalizedString("Alert.missingFolder.message", bundle:.BXMediaBrowser, comment:"Alert Message")
		
		return VStack(alignment:.leading, spacing:12)
		{
			Text(title)
				.bold()
				.lineLimit(1)
				.centerAligned()

			Text(message)
				.lineLimit(nil)
				#if os(macOS)
				.controlSize(.small)
				#endif
		}
		.padding()
		.buttonStyle(BXStrokedButtonStyle())
		.frame(width:180)
    }
}


//----------------------------------------------------------------------------------------------------------------------
