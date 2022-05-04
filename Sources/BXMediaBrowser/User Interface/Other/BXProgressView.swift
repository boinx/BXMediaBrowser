//**********************************************************************************************************************
//
//  BXProgressView.swift
//	A view with a progress bar and textual information
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import SwiftUI
import BXSwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct BXProgressView : View
{
	@ObservedObject var controller:BXProgressViewController

	private var cancelHandler:(()->Void)? = nil
	
	public init(controller:BXProgressViewController, cancelHandler:(()->Void)? = nil)
	{
		self.controller = controller
		self.cancelHandler = cancelHandler
	}
	
	public var body: some View
	{
		let title  = controller.progressTitle ?? " "
		let message = controller.progressMessage ?? " "
		
		VStack(alignment:.leading, spacing:4)
		{
			Text(title)
				.lineLimit(1)
				
			HStack
			{
				BXProgressBar(isIndeterminate:controller.isIndeterminate, value:controller.fraction, minValue:0, maxValue:1)
				
				if let cancelHandler = cancelHandler
				{
					Button(action:cancelHandler)
					{
						BXImage(systemName:"xmark.circle")
					}
				}
			}
			
			Text(message)
				.font(.caption)
				.lineLimit(1)
				.opacity(0.5)
		}
		.padding()
		.edgesIgnoringSafeArea(.all) // This is essential to make the view extend below transparent titlebar of an NSWindow!
	}
}

	
//----------------------------------------------------------------------------------------------------------------------
