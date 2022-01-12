//**********************************************************************************************************************
//
//  BXDisclosureView.swift
//	Compound views for inspector style user interfaces
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct BXDisclosureView<H,B> : View where H:View, B:View
{
	// Params
	
	private var isExpanded:Binding<Bool>
	private var headerBuilder:()->H
	private var bodyBuilder:()->B

	// Environment
	
	@Environment(\.isEnabled) private var isEnabled

	// Init
	
	public init(isExpanded:Binding<Bool>, @ViewBuilder header headerBuilder:@escaping ()->H, @ViewBuilder body bodyBuilder:@escaping ()->B)
	{
		self.isExpanded = isExpanded
		self.headerBuilder = headerBuilder
		self.bodyBuilder = bodyBuilder
	}

	// Build View
	
	public var body: some View
	{
		VStack(alignment:.leading, spacing:0)
		{
			headerBuilder()
				
			if isExpanded.wrappedValue
			{
				bodyBuilder()
			}
		}
		
	}
}


//----------------------------------------------------------------------------------------------------------------------


public struct BXDisclosureButton : View
{
	// Params
	
	private var label:String
	private var icon:CGImage?
	private var isExpanded:Binding<Bool>

	// Environment
	
	@Environment(\.font) var font

	// Init
	
	public init(_ label:String, icon:CGImage? = nil, isExpanded:Binding<Bool>)
	{
		self.label = label
		self.icon = icon
		self.isExpanded = isExpanded
	}
	
	// Build View
	
	public var body: some View
	{
		HStack(spacing:2.0)
		{
			// Disclosure triangle
			
			Text("▶︎")
				.font(font)
				.scaleEffect(0.85)
				.rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
				
				// Provide a bigger hit target for clicking the triangle
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
}


//----------------------------------------------------------------------------------------------------------------------
