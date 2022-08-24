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


struct CustomDisclosureButton : View
{
	// Params
	
	private var icon:CGImage?
	private var label:String
	private var isExpanded:Binding<Bool>

	// Environment
	
	@Environment(\.font) var font

	// Init
	
	init(icon:CGImage? = nil, label:String, isExpanded:Binding<Bool>)
	{
		self.icon = icon
		self.label = label
		self.isExpanded = isExpanded
	}
	
	// Build View
	
	public var body: some View
	{
		if #available(macOS 11.0, *)
		{
			fullAreaButton
		}
		else
		{
			fallbackButton
		}
	}
	
	
	var fullAreaButton: some View
	{
		HStack(spacing:2.0)
		{
			// Disclosure triangle
			
			BXImage(systemName:"chevron.forward")
				.scaleEffect(0.7)
				.rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
						
			// Provide a bigger hit target for clicking the triangle
			
			.overlay(
				GeometryReader
				{
					Rectangle()
						.fill(Color(white:0.0, opacity:0.01))
						.offset(x:-5, y:-5)
						.frame(width:$0.size.width+10, height:$0.size.height+14)
				}
			)

			// Optional icon
			
			if let icon = self.icon
			{
				Image(decorative:icon, scale:1)
					.resizable()
					.scaledToFit()
					.frame(width:20, height:20)
			}
				
			// Label
			
			if label.count > 0
			{
				Text(label)
					.font(font)
					.lineLimit(1)
					.truncationMode(.tail)
			}
		}
		
		// Dim when disabled
		
		.reducedOpacityWhenDisabled()
		
		// On tap toggle the disclosure state
		
		.onTapGesture
		{
			withAnimation(.easeInOut(duration:0.15))
			{
				self.isExpanded.wrappedValue.toggle()
			}
		}
	}
	
	var fallbackButton: some View
	{
		HStack(spacing:2.0)
		{
			// Disclosure triangle
			
			BXImage(systemName:"chevron.forward")
				.scaleEffect(0.7)
				.rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
						
			// On tap toggle the disclosure state
			
			.contentShape(Rectangle())
			.onTapGesture
			{
				withAnimation(.easeInOut(duration:0.15))
				{
					self.isExpanded.wrappedValue.toggle()
				}
			}
			
			// Optional icon
			
			if let icon = self.icon
			{
				Image(decorative:icon, scale:1)
					.resizable()
					.scaledToFit()
					.frame(width:20, height:20)
			}
				
			// Label
			
			if label.count > 0
			{
				Text(label)
					.font(font)
					.lineLimit(1)
					.truncationMode(.tail)
			}
		}
		
		// Dim when disabled
		
		.reducedOpacityWhenDisabled()
	}
}


//----------------------------------------------------------------------------------------------------------------------
