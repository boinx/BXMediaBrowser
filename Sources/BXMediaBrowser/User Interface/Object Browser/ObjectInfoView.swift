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


/// This struct contains the information for a single line in the ObjectInfoView

public struct ObjectMetadataEntry : Identifiable
{
	public let id:String
	public var label:String
	public var value:String
	public var popoverView:(any View)?
	public var action:(()->Void)?
	
	public init(label:String, value:String, popoverView:(any View)? = nil, action:(()->Void)? = nil)
	{
		self.id = UUID().uuidString
		self.label = label
		self.value = value
		self.popoverView = popoverView
		self.action = action
	}
}


//----------------------------------------------------------------------------------------------------------------------


public struct ObjectInfoView : View
{
	// Model
	
	@ObservedObject var object:Object
	
	// Init
	
	public init(with object:Object)
	{
		self.object = object
	}
	
	// View
	
	public var body: some View
    {
		LocalizedMetadataView(with:object.localizedMetadata)
    }
}


//----------------------------------------------------------------------------------------------------------------------


public struct LocalizedMetadataView : View
{
	// Model
	
	var localizedMetadata:[ObjectMetadataEntry]
	
	@State private var isPopoverVisible = false
	
	// Init
	
	public init(with localizedMetadata:[ObjectMetadataEntry])
	{
		self.localizedMetadata = localizedMetadata
	}
	
	// View
	
	public var body: some View
    {
		BXLabelGroup
		{
			VStack(alignment:.leading, spacing:4)
			{
				ForEach(localizedMetadata)
				{
					entry in

					BXLabelView(label:entry.label, alignment:.trailing)
					{
						Text(entry.value)
							.metadataValueStyle(for:entry)
							.optionalPopover(for:entry, state:$isPopoverVisible)
							.onOptionalTapGesture(with:entry.action)
							.lineLimit(nil)
							.fixedSize(horizontal:false, vertical:true)
					}
				}
			}
		}
		.foregroundColor(.primary)
		.frame(maxWidth:280)
		.fixedSize()
		.padding(16)
		
		#if os(macOS)
		.controlSize(.small)
		#endif
    }
}


//----------------------------------------------------------------------------------------------------------------------


public extension View
{
	@ViewBuilder func onOptionalTapGesture(with action:(()->Void)?) -> some View
	{
		if let action = action
		{
			self.onTapGesture(perform:action)
		}
		else
		{
			self
		}
	}


	@ViewBuilder func optionalPopover(for entry:ObjectMetadataEntry, state:Binding<Bool>) -> some View
	{
		if let popoverView = entry.popoverView
		{
			self.popover(isPresented:state, arrowEdge:.trailing)
			{
				AnyView(popoverView)
			}
			.onTapGesture
			{
				state.wrappedValue = true
			}
		}
		else
		{
			self
		}
	}
}


public extension Text
{
	@ViewBuilder func linkStyle(for entry:ObjectMetadataEntry) -> some View
	{
		if entry.action != nil || entry.popoverView != nil
		{
			self
				.underline()
				.foregroundColor(.accentColor)
				
				#if os(macOS)
				.cursor(.pointingHand, for:[])
				#endif
		}
		else
		{
			self
		}
	}
	
	
	@ViewBuilder func metadataValueStyle(for entry:ObjectMetadataEntry) -> some View
	{
		if entry.action != nil || entry.popoverView != nil
		{
			self.linkStyle(for:entry)
		}
		else
		{
			self.opacity(0.7)
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
