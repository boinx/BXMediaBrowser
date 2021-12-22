//**********************************************************************************************************************
//
//  View+aligned.swift
//	Adds a descriptive label below a View
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public extension View
{
	func leftAligned() -> some View
	{
		HStack
		{
			self
			Spacer()
		}
	}
	
	func rightAligned() -> some View
	{
		HStack
		{
			Spacer()
			self
		}
	}
	
	func centerAligned() -> some View
	{
		HStack
		{
			Spacer()
			self
			Spacer()
		}
	}
	
}


//----------------------------------------------------------------------------------------------------------------------

