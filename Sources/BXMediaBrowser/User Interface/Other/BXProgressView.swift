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
		VStack(alignment:.leading, spacing:8)
		{
			if let title = controller.progressTitle
			{
				Text(title)
			}
			
			HStack
			{
				#if os(macOS)
				BXSwiftUI.BXProgressBar(isIndeterminate:controller.isIndeterminate, value:controller.fraction, minValue:0, maxValue:1, size:.regular)
				#else
				
				#endif
				
				if let cancelHandler = cancelHandler
				{
					Button(action:cancelHandler)
					{
						BXImage(systemName:"xmark.circle")
					}
				}
			}
			
			if let message = controller.progressMessage
			{
				Text(message)
			}
		}
		.padding()
	}
}

	
//----------------------------------------------------------------------------------------------------------------------
